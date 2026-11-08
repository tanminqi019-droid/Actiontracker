# Meeting Action Tracker

A single-page app for tracking actions agreed in meetings.

- Add an action with an owner and a due date
- Actions grouped by owner, with a tick box for done
- Open, done and overdue counts; overdue actions highlighted in red

Data is stored in Supabase (table `public.actions`), so the whole team shares one list and changes appear live for everyone. The Supabase URL and publishable key are set at the top of the script in `index.html`. The publishable key is designed to be public; access is controlled by row-level security.

> Demo setup: there is no sign-in, so anyone with the site link can add, tick and delete actions. Add Supabase Auth before using it with real data.

## Deploy on Vercel

1. Import this repository in Vercel (Add New → Project).
2. Framework preset: **Other**. Leave the build command and output directory empty.
3. Deploy. `index.html` is served at the root.

No build step or dependencies are needed.
