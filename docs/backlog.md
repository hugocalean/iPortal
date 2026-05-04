# Qlik Sense Impersonator — Backlog

(Project formerly known as iPortal. Server-side identifiers — virtual proxy
prefix `iportal`, user directory `iportal`, CSV filenames, service-dispatcher
entry — are intentionally retained for installer/upgrade compatibility.)

## Open

- **Add authentication / authorization to the app itself.** The free-text
  impersonation form lets an operator log into Qlik Sense as any user in any
  user directory. The web app has no auth of its own, so anyone who can reach
  the URL inherits that capability. Before broader use, gate access (e.g. SSO,
  IP allowlist, or at minimum a shared secret) and consider an allowlist of
  permitted user directories.

- **Refresh dependencies.** `package.json` pins very old versions
  (`express ~4.13.1`, `winston ^2.2.0`, `hbs ~3.1.0`, `request ^2.72.0`).
  `request` has been deprecated since 2020. Run `npm audit` and plan a bump.

- **Fix `npm start` for repo-root use.** `start` currently runs
  `node Node/iPortal/server.js`, which reflects the installed layout. Either
  flip the default to `node server.js` and update the installer, or document
  that contributors should `npm run dev` (already added).

- **Move the Handlebars helper out of the request handler.**
  `routes/index.js` calls `handlebars.registerHelper('ButtonStyle', ...)`
  inside `GET /`; it re-registers on every request. Move to module load.

- **Race in `/login`.** `req.session.destroy()` is called synchronously after
  `login.requestticket(...)`, which is async. Functionally fine today, but
  reorder so the session is destroyed in the ticket-success callback.

- **Remove dead Excel loader.** `lib/users.js` and `utils/convertXlsx.js` are
  unused since the migration to CSVs (commit `6f1ba51`). Either delete or
  document why they're kept.

- **Verify against modern Qlik Sense.** README claims tested on 2.2.4 / 3.0
  (years old). The QRS/QPS contracts and certificate locations may have
  shifted; re-test against a current release before recommending broadly.
