import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const STATUS_VALUES = new Set(["trial", "active", "suspended", "expired"]);

function generateTemporaryPassword() {
  const bytes = new Uint8Array(18);
  crypto.getRandomValues(bytes);
  return `Zp!${Array.from(bytes, (byte) => byte.toString(36).padStart(2, "0")).join("")}`;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let authUserId: string | null = null;
  let academyId: string | null = null;

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

    const { data: requesterProfile, error: profileError } = await adminClient
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();
    if (profileError || requesterProfile?.role !== "super_admin") {
      throw new Error("Only a super admin can create academy owners");
    }

    const body = await request.json();
    const applicationId = String(body.application_id || "").trim();
    let source = body;

    if (applicationId) {
      const { data: application, error: applicationError } = await adminClient
        .from("academy_owner_applications")
        .select("id, academy_name, academy_code, owner_name, owner_email, expected_students, status")
        .eq("id", applicationId)
        .eq("status", "pending")
        .single();
      if (applicationError || !application) {
        throw new Error("Pending academy owner application not found");
      }

      source = {
        academy_name: application.academy_name,
        academy_code: application.academy_code,
        owner_display_name: application.owner_name,
        owner_email: application.owner_email,
        password: generateTemporaryPassword(),
        status: body.status || "active",
        student_limit: application.expected_students || 100,
      };
    }

    const academyName = String(source.academy_name || "").trim();
    const academyCode = String(source.academy_code || "")
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9_-]/g, "");
    const ownerDisplayName = String(source.owner_display_name || "").trim();
    const ownerEmail = String(source.owner_email || "").trim().toLowerCase();
    const password = String(source.password || "");
    const status = String(source.status || "active").trim();
    const studentLimit = source.student_limit === undefined
      ? 100
      : Number(source.student_limit);

    if (academyName.length < 2 || academyName.length > 80) {
      throw new Error("Academy name must be 2-80 characters");
    }
    if (!/^[A-Z0-9][A-Z0-9_-]{2,23}$/.test(academyCode)) {
      throw new Error("Academy code must be 3-24 letters, numbers, - or _");
    }
    if (ownerDisplayName.length < 2 || ownerDisplayName.length > 60) {
      throw new Error("Owner display name must be 2-60 characters");
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(ownerEmail)) {
      throw new Error("Enter a valid owner email");
    }
    if (password.length < 8) {
      throw new Error("Temporary password must be at least 8 characters");
    }
    if (!STATUS_VALUES.has(status)) {
      throw new Error("Invalid academy status");
    }
    if (!Number.isInteger(studentLimit) || studentLimit < 1 || studentLimit > 5000) {
      throw new Error("Student limit must be between 1 and 5000");
    }

    const { data: authData, error: authError } =
      await adminClient.auth.admin.createUser({
        email: ownerEmail,
        password,
        email_confirm: true,
        user_metadata: {
          role: "academy_owner",
          academy_code: academyCode,
          display_name: ownerDisplayName,
        },
      });
    if (authError || !authData.user) {
      throw new Error(authError?.message || "Could not create owner login");
    }
    authUserId = authData.user.id;

    const { data: academy, error: academyError } = await adminClient
      .from("academies")
      .insert({
        name: academyName,
        code: academyCode,
        owner_id: authUserId,
        owner_email: ownerEmail,
        status,
        student_limit: studentLimit,
      })
      .select("id, name, code, owner_email, status, student_limit, created_at")
      .single();
    if (academyError || !academy) {
      throw new Error(academyError?.message || "Could not create academy");
    }
    academyId = academy.id;

    const { error: profileInsertError } = await adminClient
      .from("profiles")
      .insert({
        id: authUserId,
        academy_id: academyId,
        role: "academy_owner",
        display_name: ownerDisplayName,
      });
    if (profileInsertError) {
      throw new Error(profileInsertError.message);
    }

    if (applicationId) {
      const { error: applicationUpdateError } = await adminClient
        .from("academy_owner_applications")
        .update({
          status: "approved",
          reviewed_by: user.id,
          reviewed_at: new Date().toISOString(),
          created_academy_id: academy.id,
        })
        .eq("id", applicationId)
        .eq("status", "pending");
      if (applicationUpdateError) {
        throw new Error(applicationUpdateError.message);
      }
    }

    return new Response(JSON.stringify({ academy, owner_email: ownerEmail }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 201,
    });
  } catch (error) {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (supabaseUrl && serviceRoleKey && (academyId || authUserId)) {
      const adminClient = createClient(supabaseUrl, serviceRoleKey);
      if (academyId) {
        await adminClient.from("academies").delete().eq("id", academyId);
      }
      if (authUserId) {
        await adminClient.auth.admin.deleteUser(authUserId);
      }
    }

    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
