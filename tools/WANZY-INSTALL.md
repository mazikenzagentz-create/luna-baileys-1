# WANZY OFFICIAL — Nerxa Cosmic Theme

Original Pterodactyl Panel v1.x dashboard theme inspired by Nerxa / Marchel Tech.

Visuals:
- Deep charcoal base (#08090d).
- Violet and fuchsia highlights, cyan details, emerald status accents.
- Animated star field and CSS 3D crystal on the dashboard.
- Responsive layout and reduced-motion support.
- No added npm dependencies and no database migrations.

Install on the Pterodactyl host VPS as root (not inside a game-server container):

```bash
curl -fsSL https://raw.githubusercontent.com/mazikenzagentz-create/luna-baileys-1/main/tools/wanzy-install.sh -o /tmp/wanzy-install.sh
chmod +x /tmp/wanzy-install.sh
bash /tmp/wanzy-install.sh
```

The installer expects the panel at /var/www/pterodactyl. It creates a timestamped backup under /var/backups/wanzy-official/ before changing App.tsx, DashboardContainer.tsx, and the frontend assets. It does not run database migrations or install npm packages. If the frontend build fails, it restores the backed-up source and public assets.

Keep a VPS snapshot and run during a maintenance window.