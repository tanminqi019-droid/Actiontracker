# Meeting Action Tracker

A single-page app for tracking actions agreed in meetings.

- Add an action with an owner and a due date
- Actions grouped by owner, with a tick box for done
- Open, done and overdue counts; overdue actions highlighted in red

Data is stored in Supabase (table `public.actions`), so the whole team shares one list and changes appear live for everyone. The Supabase URL and publishable key are set at the top of the script in `index.html`. The publishable key is designed to be public; access is controlled by row-level security.

## Sign-in and users

- Everyone signs in with a username and password (Supabase Auth, stored in `auth.users`). Nothing is visible until you sign in.
- Usernames map to `<username>@example.com` behind the scenes.
- Demo accounts: `alif` (admin), `christina`, `charlene`, `jasmine`, `karen`, `leonard`, `steph`. Default password: `password`.
- Admins see **Manage team**, where they can add users with an initial password and reset passwords. This runs through the `admin-users` Edge Function, which checks the caller is an admin.
- Public self sign-up is blocked: only admin-created accounts are accepted.

## Deploy on Vercel

1. Import this repository in Vercel (Add New → Project).
2. Framework preset: **Other**. Leave the build command and output directory empty.
3. Deploy. `index.html` is served at the root.

No build step or dependencies are needed.

## Database

- `supabase/migrations/` creates the `actions` table, its access policies and realtime.
- `supabase/seed.sql` loads the mock team actions.
- `supabase/seed_users.sql` creates the demo team accounts.
- `supabase/functions/admin-users/` is the Edge Function for adding users and resetting passwords (deploy with `verify_jwt` off; it checks auth itself).

To set up a fresh Supabase project, run the migrations in order, then `seed_users.sql` and `seed.sql`, deploy the Edge Function, in the SQL Editor, and update `SUPABASE_URL` and `SUPABASE_KEY` in `index.html`.
