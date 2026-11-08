-- Demo team accounts in Supabase Auth (auth.users). Default password: "password".
-- Usernames sign in as <username>@example.com. Alif is the admin.
-- Change these passwords from the app's "Manage team" panel before real use.
with team(display_name, role) as (values
  ('Alif','admin'),('Christina','member'),('Charlene','member'),('Jasmine','member'),
  ('Karen','member'),('Leonard','member'),('Steph','member')
), new_users as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change, email_change_token_new, email_change_token_current, reauthentication_token
  )
  select
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    lower(display_name) || '@example.com',
    extensions.crypt('password', extensions.gen_salt('bf')),
    now(),
    jsonb_build_object('provider','email','providers',jsonb_build_array('email'),'role',role,'created_by_admin',true),
    jsonb_build_object('username', lower(display_name), 'display_name', display_name),
    now(), now(), '', '', '', '', '', ''
  from team
  returning id, email
)
insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select id::text, id, jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true), 'email', now(), now(), now()
from new_users;
