// Admin-only user management for the Meeting Action Tracker.
// Actions: "create" (add a user with an initial password) and "reset_password".
// Auth is checked in the function body: the caller must be signed in and have role 'admin' in public.profiles.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const EMAIL_DOMAIN = "example.com"; // usernames are stored as <username>@example.com in auth.users

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 1. Who is calling?
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "Please sign in." }, 401);
  const { data: userData, error: userErr } = await admin.auth.getUser(token);
  if (userErr || !userData?.user) return json({ error: "Your session has expired. Please sign in again." }, 401);

  // 2. Are they an admin?
  const { data: me } = await admin.from("profiles").select("role").eq("id", userData.user.id).single();
  if (me?.role !== "admin") return json({ error: "Only admins can manage users." }, 403);

  let body: Record<string, string>;
  try { body = await req.json(); } catch { return json({ error: "Invalid request." }, 400); }

  const password = String(body.password ?? "");
  if (password.length < 6) return json({ error: "Password must be at least 6 characters." }, 400);

  if (body.action === "create") {
    const displayName = String(body.display_name ?? "").trim().replace(/\s+/g, " ");
    const username = String(body.username ?? "").trim().toLowerCase();
    const role = body.role === "admin" ? "admin" : "member";
    if (!displayName || displayName.length > 40) return json({ error: "Please add a name (up to 40 characters)." }, 400);
    if (!/^[a-z0-9._-]{2,30}$/.test(username)) {
      return json({ error: "Username must be 2–30 characters: letters, numbers, dots, dashes or underscores." }, 400);
    }
    const { data: taken } = await admin.from("profiles").select("id").eq("username", username).maybeSingle();
    if (taken) return json({ error: `The username "${username}" is already taken.` }, 409);

    const { data, error } = await admin.auth.admin.createUser({
      email: `${username}@${EMAIL_DOMAIN}`,
      password,
      email_confirm: true,
      user_metadata: { username, display_name: displayName },
      app_metadata: { role, created_by_admin: true }, // only the server can set app_metadata
    });
    if (error) return json({ error: error.message }, 400);
    return json({ ok: true, id: data.user.id, username, display_name: displayName, role });
  }

  if (body.action === "reset_password") {
    const userId = String(body.user_id ?? "");
    if (!userId) return json({ error: "No user selected." }, 400);
    const { error } = await admin.auth.admin.updateUserById(userId, { password });
    if (error) return json({ error: error.message }, 400);
    return json({ ok: true });
  }

  return json({ error: "Unknown action." }, 400);
});
