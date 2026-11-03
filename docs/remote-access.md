# Remote access (optional)

Useful while installing Battle.net from another machine. Not required for couch play.

| Tool | Purpose |
|------|---------|
| SSH | Scripts, file ops |
| Sunshine + Moonlight | Interactive Desktop Mode GUI |
| RustDesk | Alternate remote desktop |
| Tailscale | Off-LAN access (enable on the host if you need it) |

## SSH

```bash
ssh user@your-bazzite-host
```

## Sunshine / Moonlight

1. Ensure Sunshine is running on the Bazzite box.
2. Pair Moonlight with the PIN shown in the Sunshine web UI.
3. For installers: switch the host to Desktop Mode (`steamos-session-select desktop`), then return later with `steamos-session-select gamescope`.

Store any Sunshine web password **outside git** (for example a local `config/sunshine-web-password.txt` that is already gitignored).

## Security

- Prefer LAN or a VPN (Tailscale) before exposing remote-desktop ports.
- Do not commit passwords, Battle.net credentials, or machine-specific inventory dumps.
