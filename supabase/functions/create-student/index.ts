import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = request.headers.get("Authorization");
    if (!authHeader) throw new Error("Authentication required");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) throw new Error("Invalid login");

    const { data: ownerProfile, error: profileError } = await adminClient
      .from("profiles")
      .select("academy_id, role")
      .eq("id", user.id)
      .single();
    if (profileError || !ownerProfile) throw new Error("Owner profile not found");
    if (!["academy_owner", "teacher"].includes(ownerProfile.role)) {
      throw new Error("Only academy staff can create students");
    }

    const body = await request.json();
    const englishName = String(body.english_name || "").trim();
    const studentLoginId = String(body.student_login_id || "")
      .trim()
      .toLowerCase();
    const password = String(body.password || "");

    if (!/^[A-Za-z][A-Za-z .'-]{0,39}$/.test(englishName)) {
      throw new Error("Enter a valid English name");
    }
    if (!/^[a-z0-9][a-z0-9._-]{3,23}$/.test(studentLoginId)) {
      throw new Error("Student ID must be 4-24 lowercase letters or numbers");
    }
    if (password.length < 6) {
      throw new Error("Password must be at least 6 characters");
    }

    const { data: academy, error: academyError } = await adminClient
      .from("academies")
      .select("code, status, student_limit")
      .eq("id", ownerProfile.academy_id)
      .single();
    if (academyError || !academy) throw new Error("Academy not found");
    if (!["trial", "active"].includes(academy.status)) {
      throw new Error("Academy access is not active");
    }

    const { count } = await adminClient
      .from("students")
      .select("id", { count: "exact", head: true })
      .eq("academy_id", ownerProfile.academy_id)
      .neq("status", "archived");
    if ((count || 0) >= academy.student_limit) {
      throw new Error("Student limit reached");
    }

    const syntheticEmail =
      `${academy.code.toLowerCase()}.${studentLoginId}` +
      "@students.zoopspop.invalid";

    const { data: authData, error: authError } =
      await adminClient.auth.admin.createUser({
        email: syntheticEmail,
        password,
        email_confirm: true,
        user_metadata: {
          role: "student",
          academy_id: ownerProfile.academy_id,
          english_name: englishName,
        },
      });
    if (authError || !authData.user) {
      throw new Error(authError?.message || "Could not create login");
    }

    const authUserId = authData.user.id;
    const { error: insertError } = await adminClient.from("profiles").insert({
      id: authUserId,
      academy_id: ownerProfile.academy_id,
      role: "student",
      display_name: englishName,
    });

    if (!insertError) {
      const { data: student, error: studentError } = await adminClient
        .from("students")
        .insert({
          academy_id: ownerProfile.academy_id,
          auth_user_id: authUserId,
          english_name: englishName,
          student_login_id: studentLoginId,
          created_by: user.id,
        })
        .select("id, english_name, student_login_id, status, created_at")
        .single();

      if (!studentError) {
        return new Response(JSON.stringify({ student }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 201,
        });
      }
    }

    await adminClient.auth.admin.deleteUser(authUserId);
    throw new Error(insertError?.message || "Could not save student");
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
