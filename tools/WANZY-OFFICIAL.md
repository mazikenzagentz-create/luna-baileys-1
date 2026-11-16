# Wanzy Official — Pterodactyl Theme Installer

Installer script: [tools/wanzy-official.sh](./wanzy-official.sh)

Run on the **VPS host** as root (not inside a Pterodactyl game-server container):

```bash
curl -fsSL https://raw.githubusercontent.com/mazikenzagentz-create/luna-baileys-1/main/tools/wanzy-official.sh -o /tmp/wanzy-official.sh
chmod +x /tmp/wanzy-official.sh
bash /tmp/wanzy-official.sh
```

The installer expects the panel at `/var/www/pterodactyl`. It creates backups under `/var/backups/wanzy-official` before overlaying theme files. Review the script and confirm your panel path and compatibility before applying a theme. Keep a VPS backup and run during a maintenance window.
