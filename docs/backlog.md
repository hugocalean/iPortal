# iPortal Backlog

## Open

- **Add authentication / authorization to iPortal itself.** The free-text
  impersonation form lets an operator log into Qlik Sense as any user in any
  user directory. Today the iPortal web app has no auth of its own, so anyone
  who can reach the URL inherits that capability. Before broader use, gate
  iPortal access (e.g. SSO, IP allowlist, or at minimum a shared secret) and
  consider an allowlist of permitted user directories.
