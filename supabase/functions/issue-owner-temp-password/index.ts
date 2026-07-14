import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function generateTemporaryPassword() {
  const bytes = new Uint8Array(8);
  crypto.getRandomValues(bytes);
  const token = Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");
  return `Zoops!${token}`;
}

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

    const { data: requesterProfile, error: profileError } = await adminClient
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();
    if (profileError || requesterProfile?.role !== "super_admin") {
      throw new Error("Only a super admin can issue temporary passwords");
    }

    const body = await request.json();
    const academyId = String(body.academy_id || "").trim();
    if (!academyId) throw new Error("Academy id is required");

    const { data: academy, error: academyError } = await adminClient
      .from("academies")
      .select("id, owner_id, owner_email")
      .eq("id", academyId)
      .single();
    if (academyError || !academy?.owner_id || !academy?.owner_email) {
      throw new Error("Academy owner account not found");
    }

    const temporaryPassword = generateTemporaryPassword();
    const { error: updateError } = await adminClient.auth.admin.updateUserById(
      academy.owner_id,
      { password: temporaryPassword },
    );
    if (updateError) {
      throw new Error(updateError.message);
    }

    return new Response(JSON.stringify({
      owner_email: academy.owner_email,
      temporary_password: temporaryPassword,
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
