# Meeting Action Tracker

A single-page app for tracking actions agreed in meetings.

- Add an action with an owner and a due date
- Actions grouped by owner, with a tick box for done
- Open, done and overdue counts; overdue actions highlighted in red

Data is saved in the browser's local storage, so each browser keeps its own list.

## Deploy on Vercel

1. Import this repository in Vercel (Add New → Project).
2. Framework preset: **Other**. Leave the build command and output directory empty.
3. Deploy. `index.html` is served at the root.

No build step or dependencies are needed.
