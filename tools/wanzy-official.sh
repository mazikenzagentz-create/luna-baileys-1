#!/usr/bin/env bash
set -Eeuo pipefail
PANEL_DIR="\${PANEL_DIR:-/var/www/pterodactyl}"
BACKUP_ROOT="/var/backups/wanzy-official"
RAW_BASE="https://raw.githubusercontent.com/mazikenzagentz-create/luna-baileys-1/main/tools/wanzy-theme"
TMP_DIR=""
BACKUP_DIR=""
RESET=$'\033[0m'
CYAN=$'\033[38;5;45m'
PURPLE=$'\033[38;5;141m'
GREEN=$'\033[38;5;82m'
YELLOW=$'\033[38;5;220m'
RED=$'\033[38;5;203m'
say(){ printf '  %b›%b %s\n' "$CYAN" "$RESET" "$*"; }
ok(){ printf '  %b✓%b %s\n' "$GREEN" "$RESET" "$*"; }
warn(){ printf '  %b!%b %s\n' "$YELLOW" "$RESET" "$*"; }
die(){ printf '  %b✕%b %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
cleanup(){ [[ -z "$TMP_DIR" || ! -d "$TMP_DIR" ]] || rm -rf -- "$TMP_DIR"; }
trap cleanup EXIT
banner(){
  clear 2>/dev/null || true
  printf '%b\n' "$CYAN" '██╗    ██╗ █████╗ ███╗   ██╗███████╗██╗   ██╗'
  printf '%b\n' "$PURPLE" '██║    ██║██╔══██╗████╗  ██║╚══███╔╝╚██╗ ██╔╝'
  printf '%b\n' "$CYAN" '██║ █╗ ██║███████║██╔██╗ ██║  ███╔╝  ╚████╔╝ '
  printf '%b\n' "$PURPLE" '██║███╗██║██╔══██║██║╚██╗██║ ███╔╝    ╚██╔╝  '
  printf '%b\n' "$CYAN" '╚███╔███╔╝██║  ██║██║ ╚████║███████╗   ██║   '
  printf '%b\n' "$PURPLE" ' ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   '
  printf '\n%bWANZY OFFICIAL — NERXA COSMIC THEME%b\n\n' "$PURPLE" "$RESET"
}
rollback(){
  [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]] || return 0
  warn "Mengembalikan file sumber dari backup..."
  cp -a "$BACKUP_DIR/App.tsx" "$PANEL_DIR/resources/scripts/components/App.tsx"
  cp -a "$BACKUP_DIR/DashboardContainer.tsx" "$PANEL_DIR/resources/scripts/components/dashboard/DashboardContainer.tsx"
  if [[ -f "$BACKUP_DIR/wanzy-official.css" ]]; then cp -a "$BACKUP_DIR/wanzy-official.css" "$PANEL_DIR/resources/scripts/assets/wanzy-official.css"; else rm -f "$PANEL_DIR/resources/scripts/assets/wanzy-official.css"; fi
  if [[ -f "$BACKUP_DIR/WanzyHomeHero.tsx" ]]; then cp -a "$BACKUP_DIR/WanzyHomeHero.tsx" "$PANEL_DIR/resources/scripts/components/dashboard/WanzyHomeHero.tsx"; else rm -f "$PANEL_DIR/resources/scripts/components/dashboard/WanzyHomeHero.tsx"; fi
  if [[ -d "$BACKUP_DIR/public-assets" ]]; then rm -rf "$PANEL_DIR/public/assets"; cp -a "$BACKUP_DIR/public-assets" "$PANEL_DIR/public/assets"; fi
}
main(){
  [[ "$EUID" == 0 ]] || die "Jalankan sebagai root."
  command -v curl >/dev/null || die "curl belum tersedia."
  command -v python3 >/dev/null || die "python3 belum tersedia."
  command -v php >/dev/null || die "PHP belum tersedia."
  command -v yarn >/dev/null || die "Yarn belum tersedia."
  [[ -f "$PANEL_DIR/artisan" && -f "$PANEL_DIR/resources/scripts/components/App.tsx" && -f "$PANEL_DIR/resources/scripts/components/dashboard/DashboardContainer.tsx" ]] || die "Struktur panel tidak cocok: $PANEL_DIR"
  banner
  printf '  Tema: %bWANZY OFFICIAL%b\n' "$PURPLE" "$RESET"
  printf '  Palet: deep dark · violet · fuchsia · cyan · emerald\n'
  printf '  Home: starfield + lightweight CSS 3D crystal\n\n'
  warn "Installer akan mengubah dua file React dan menambahkan dua file tema."
  warn "Tidak menjalankan database migration dan tidak menambah dependency."
  read -r -p "  Lanjutkan? [y/N] " confirm
  [[ "$confirm" == "y" || "$confirm" == "Y" ]] || { say "Dibatalkan."; exit 0; }
  TMP_DIR="$(mktemp -d /tmp/wanzy-official.XXXXXX)"
  mkdir -p "$BACKUP_ROOT"; chmod 700 "$BACKUP_ROOT"
  BACKUP_DIR="$BACKUP_ROOT/$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$BACKUP_DIR"
  cp -a "$PANEL_DIR/resources/scripts/components/App.tsx" "$BACKUP_DIR/App.tsx"
  cp -a "$PANEL_DIR/resources/scripts/components/dashboard/DashboardContainer.tsx" "$BACKUP_DIR/DashboardContainer.tsx"
  [[ ! -d "$PANEL_DIR/public/assets" ]] || cp -a "$PANEL_DIR/public/assets" "$BACKUP_DIR/public-assets"
  [[ ! -f "$PANEL_DIR/resources/scripts/assets/wanzy-official.css" ]] || cp -a "$PANEL_DIR/resources/scripts/assets/wanzy-official.css" "$BACKUP_DIR/wanzy-official.css"
  [[ ! -f "$PANEL_DIR/resources/scripts/components/dashboard/WanzyHomeHero.tsx" ]] || cp -a "$PANEL_DIR/resources/scripts/components/dashboard/WanzyHomeHero.tsx" "$BACKUP_DIR/WanzyHomeHero.tsx"
  for file in WanzyHomeHero.tsx wanzy-official.css; do
    say "Mengunduh $file..."
    curl --fail --location --silent --show-error --retry 2 "$RAW_BASE/$file" -o "$TMP_DIR/$file"
    [[ -s "$TMP_DIR/$file" ]] || die "File $file kosong."
  done
  install -D -m 0644 "$TMP_DIR/WanzyHomeHero.tsx" "$PANEL_DIR/resources/scripts/components/dashboard/WanzyHomeHero.tsx"
  install -D -m 0644 "$TMP_DIR/wanzy-official.css" "$PANEL_DIR/resources/scripts/assets/wanzy-official.css"
  if ! python3 - "$PANEL_DIR/resources/scripts/components/App.tsx" "$PANEL_DIR/resources/scripts/components/dashboard/DashboardContainer.tsx" <<'PY'
from pathlib import Path
import sys
app_path, dash_path = map(Path, sys.argv[1:])
app = app_path.read_text()
css_import = "import '@/assets/wanzy-official.css';"
if css_import not in app:
    anchor = "import '@/assets/tailwind.css';"
    if anchor not in app:
        raise SystemExit("Tidak menemukan import tailwind.css di App.tsx.")
    app = app.replace(anchor, anchor + "\n" + css_import, 1)
dash = dash_path.read_text()
hero_import = "import WanzyHomeHero from '@/components/dashboard/WanzyHomeHero';"
if hero_import not in dash:
    lines = dash.splitlines()
    last_import = max((i for i, line in enumerate(lines) if line.startswith("import ")), default=-1)
    if last_import < 0:
        raise SystemExit("Import DashboardContainer.tsx tidak dikenali.")
    lines.insert(last_import + 1, hero_import)
    dash = "\n".join(lines) + ("\n" if dash.endswith("\n") else "")
if "<WanzyHomeHero />" not in dash:
    marker = "<PageContentBlock title={'Dashboard'} showFlashKey={'dashboard'}>"
    if marker not in dash:
        raise SystemExit("Struktur dashboard tidak cocok.")
    dash = dash.replace(marker, marker + "\n            <WanzyHomeHero />", 1)
app_path.write_text(app)
dash_path.write_text(dash)
PY
  then
    rollback
    die "Patch source tidak cocok. File lama sudah dipulihkan."
  fi
  say "Membangun frontend Pterodactyl..."
  cd "$PANEL_DIR"
  if ! yarn build:production; then
    rollback
    die "Build gagal. File sumber dikembalikan. Backup: $BACKUP_DIR"
  fi
  chown www-data:www-data "$PANEL_DIR/resources/scripts/assets/wanzy-official.css" "$PANEL_DIR/resources/scripts/components/dashboard/WanzyHomeHero.tsx"
  chown -R www-data:www-data "$PANEL_DIR/public/assets"
  php artisan view:clear
  php artisan config:clear
  ok "WANZY OFFICIAL berhasil dipasang."
  ok "Backup tersimpan: $BACKUP_DIR"
  say "Hard refresh browser untuk melihat tema baru."
}
main "$@"
