# Qlik Sense Impersonator

[![Project Status: Unsupported – The project has reached a stable, usable state but the author(s) have ceased all work on it. A new maintainer may be desired.](https://www.repostatus.org/badges/latest/unsupported.svg)](https://www.repostatus.org/#unsupported)

> Formerly known as **iPortal**. The product has been renamed to **Qlik Sense Impersonator**, but the server-side identifiers it relies on (Qlik virtual-proxy prefix `iportal`, user-directory name `iportal`, CSV filenames `iportal_users.csv` / `iportal_attributes.csv`, service-dispatcher entry `[iportal]`) are intentionally unchanged so that existing installs and the bundled installer keep working.

Qlik Sense Impersonator is a small Node.js web app that lets you log into Qlik Sense as any user without their password. It calls Qlik's official QPS ticketing API over mutual TLS, using the local certificates the Qlik Sense Repository exports for the host.

> **Not for production.** It has no authentication of its own — anyone who can reach the URL inherits the ability to impersonate any user in any user directory. Use it on a closed test/demo environment.

## Features

- **Curated user grid.** Cards rendered from `udc/iportal_users.csv` + `udc/iportal_attributes.csv`, with per-user image, title, group memberships, and per-user app buttons (Hub, QMC, etc.).
- **Free-text impersonation form.** Type any `userId` and `userDirectory`, pick an app from the dropdown, and log in as that user. Useful for previewing what an arbitrary user can see *before* granting them access.
- **Multi-app launcher.** Apps and their target paths come from `udc/app_paths.csv`, including non-Qlik apps (the `boolAuth=false` flag bypasses ticket auth and just redirects).
- **Themed avatars.** `cfg.theme` selects an image set under `public/images/<theme>/` (default `clipart`).
- **Bundled installer for Qlik Sense.** Provisions the virtual proxy, ODBC-style User Directory Connector, and a service-dispatcher entry so the app auto-starts with Qlik Sense.

## How it works

1. Browser hits `GET /` and sees a grid of users plus the free-text form.
2. Clicking a button hits `GET /login?user=<id>&directory=<udc>&app=<name>`.
3. `routes/index.js` looks up the app in `app_paths.csv`. If `boolAuth=false`, it redirects directly. Otherwise it calls `lib/login.js`.
4. `lib/login.js` issues a mutual-TLS POST to `https://<host>:<qpsPort>/qps/<virtualProxy>/ticket` with `{userDirectory, UserId}` — Qlik returns a one-shot ticket.
5. The browser is redirected to `https://<host>/<virtualProxy><appPath>?Qlikticket=<ticket>` and is logged into Qlik as the chosen user.

## Prerequisites

- Windows host running **Qlik Sense Enterprise** (tested with 2.2.4 and 3.0 — older versions; behavior on newer releases not verified).
- **Node.js** (the bundled service dispatcher uses Qlik's own `Node\node.exe`).
- Qlik Sense's exported local certificates present at:
  `%programdata%\Qlik\Sense\Repository\Exported Certificates\.Local Certificates\` (`server.pem`, `server_key.pem`, `client.pem`, `client_key.pem`, `root.pem`).
- A free TCP port (default `3090`) for the impersonator's HTTPS listener.

## Installation — automated installer (recommended)

Download the latest installer from the **[Releases page](https://github.com/eapowertools/iPortal/releases/latest)**. The installer:

1. Lays the app out under `<Qlik install>\EAPowerTools\iportal\`.
2. Creates the Qlik virtual proxy `iportal` (via `utils/createVirtualProxy.js` → QRS API).
3. Creates and syncs an ODBC User Directory Connector named `iportal` pointing at `udc\iportal_users.csv` and `udc\iportal_attributes.csv` (via `utils/createUDC.js`).
4. Registers the app with the Qlik Sense service dispatcher by appending `config/services.conf.cfg` to `services.conf` (via `utils/ServicesConfBuilder.ps1`) so it auto-starts.
5. Starts/restarts the dispatcher service (`utils/startService.bat`).

After install, browse to `https://<host>:3090/`.

To configure security rules, custom properties, and tags for the Governed Self-Service reference deployment, follow the **[GSS Setup Guide](docs/gss_setup_guide.md)**.

## Installation — manual

If you can't run the installer, the same effect can be achieved by hand:

1. Copy the repo to `<Qlik install>\EAPowerTools\iportal\` (or any location reachable by Qlik's Node).
2. `npm install` from that directory.
3. Edit `config/config.js` and set `hostname` to your Qlik server's FQDN. Override `serverPort`, `qpsPort`, `qrsPort`, `virtualProxy`, `userDirectory`, or `sessionSecret` if your environment differs.
4. Use `utils/createVirtualProxy.bat` and `utils/createUDC.bat` (which shell out to the Node helpers) to provision the virtual proxy and UDC, or create them manually in the QMC matching `utils/createVP.json` and `utils/udcDef.json`.
5. Append the contents of `config/services.conf.cfg` to your service dispatcher's `services.conf`, then restart the **Qlik Sense Service Dispatcher** Windows service.

## Running locally (developer mode)

The `npm start` script in `package.json` (`node Node/iPortal/server.js`) reflects the **installed** layout, not the repo layout. To run from a checked-out copy, start the server directly:

```
node server.js
```

The process expects Qlik's local certificates at the path above and will exit with an error if they are missing.

## Configuration

`config/config.js` exposes the following knobs (defaults shown):

| Key                | Default              | Notes                                                                 |
|--------------------|----------------------|-----------------------------------------------------------------------|
| `serverPort`       | `3090`               | HTTPS port the impersonator listens on.                               |
| `qpsPort`          | `4243`               | Qlik Proxy Service port (used for ticket requests).                   |
| `qrsPort`          | `4242`               | Qlik Repository Service port (used by installer helpers).             |
| `hostname`         | `senseServerName`    | **Must be set** to the Qlik Sense host FQDN.                          |
| `virtualProxy`     | `iportal`            | Virtual proxy prefix. Don't change without re-provisioning Qlik.      |
| `userDirectory`    | `iportal`            | UDC name. Don't change without re-provisioning Qlik.                  |
| `sessionSecret`    | `iportal-secret`     | Express session secret. Override in any non-toy install.              |
| `theme`            | `clipart`            | Subdirectory under `public/images/` used for user avatars.            |
| `logLevel`         | `debug`              | winston log level.                                                    |
| `certificates.*`   | derived from `%programdata%` | Paths to Qlik's exported local certificates. |

## Updating the user list

The displayed users come from three CSVs in `udc/`:

- **`iportal_users.csv`** — `userid,name`
- **`iportal_attributes.csv`** — long-form `userid,type,value` rows. Recognized `type` values: `group`, `app`, `image`, `udc`, `title` (anything else is attached as a generic property).
- **`app_paths.csv`** — `appName,port,path,boolAuth`. `boolAuth=false` means "redirect, don't ticket-auth" (used for non-Qlik companion apps like the GMS demo).

After editing the user/attribute CSVs, trigger a UDC sync in the QMC so Qlik picks up the new users. The Qlik UDC reads the same CSV files, so the impersonator and Qlik stay in sync.

A legacy Excel-driven loader (`lib/users.js`) and the converter `utils/convertXlsx.js` are kept for back-compat with `udc/excel/iportal_users.xlsx`, but the active code path is the CSV loader (`lib/parseUdcFiles.js`).

## Project layout

```
server.js                  HTTPS server bootstrap
app.js                     Express app: sessions, views, static, router
config/
  config.js                Runtime config (ports, hostname, cert paths)
  services.conf.cfg        Snippet appended to Qlik's service dispatcher
routes/
  index.js                 GET / (grid + form), GET /login (ticket + redirect)
lib/
  login.js                 Mutual-TLS ticket request to QPS
  parseUdcFiles.js         CSV → users/attributes loader (active)
  appPaths.js              CSV → apps loader
  users.js                 Legacy Excel loader (unused)
  qrsinteractions.js       QRS REST helper used by installer scripts
views/
  layout.hbs               Page chrome
  index.hbs                User grid + free-text impersonation form
  error.hbs, autherror.hbs Error pages
public/                    Static assets (CSS, JS, images, fonts)
udc/
  iportal_users.csv        Demo users
  iportal_attributes.csv   Per-user attributes
  app_paths.csv            Launchable apps
  excel/                   Legacy xlsx source
utils/                     Installer helpers (Node + .bat + .ps1)
docs/
  gss_setup_guide.md       Governed Self-Service configuration walkthrough
  backlog.md               Open work / known issues
```

## Known limitations and backlog

See [`docs/backlog.md`](docs/backlog.md) for tracked items. Highlights from the latest end-to-end review:

- **No app-level authentication.** Everyone with network reach can impersonate anyone. Gate behind SSO, IP allowlist, or at minimum a shared secret before broader use.
- **`request` is deprecated** and several dependencies (`express ~4.13.1`, `winston ^2.2.0`, `hbs ~3.1.0`) are years out of date — likely transitive vulnerabilities. Audit before any non-disposable deployment.
- **`npm start` references an installed-only path** (`node Node/iPortal/server.js`). Run `node server.js` from the repo root in dev.
- **Handlebars helper is registered per-request** in `routes/index.js`. Harmless today, but should move to module load.
- **`req.session.destroy()` runs before the async ticket call resolves** in `routes/index.js`. Works because the response object is still valid, but is a smell.
- **`lib/users.js` is dead code** since the move from xlsx to csv (commit `6f1ba51`).

## License

Qlik Sense Impersonator (and the broader EA Power Tools collection) is provided **free of charge and unsupported by Qlik**. It uses Qlik APIs but is open source and provided without warranty. Use at your own risk.

For background, see the [EAPowertools](https://community.qlik.com/community/qlik-sense/ea-powertools) space on Qlik Community.
