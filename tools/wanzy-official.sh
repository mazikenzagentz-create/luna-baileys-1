#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="1.0.0"
PANEL_DIR="/var/www/pterodactyl"
BACKUP_ROOT="/var/backups/wanzy-official"
THEME_BASE="https://cdn.jsdelivr.net/gh/Bangsano/themeinstaller@main/theme"
TMP_DIR=""
BACKUP_DIR=""
THEME_NAME=""
THEME_URL=""
BUILD_REQUIRED=0
LINK_ADMIN=""
LINK_CHANNEL=""
LINK_GROUP=""

RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
CYAN=$'\033[38;5;45m'
VIOLET=$'\033[38;5;141m'
GREEN=$'\033[38;5;82m'
YELLOW=$'\033[38;5;220m'
RED=$'\033[38;5;203m'
WHITE=$'\033[97m'

cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then rm -rf -- "$TMP_DIR"; fi
}
trap cleanup EXIT

ok() { printf '  %b✓%b %s\n' "$GREEN" "$RESET" "$*"; }
info() { printf '  %b›%b %s\n' "$CYAN" "$RESET" "$*"; }
warn() { printf '  %b!%b %s\n' "$YELLOW" "$RESET" "$*"; }
fail() { printf '  %b✕%b %s\n' "$RED" "$RESET" "$*" >&2; }

banner() {
  clear 2>/dev/null || true
  printf '\n%b\n' "$CYAN"'██╗    ██╗ █████╗ ███╗   ██╗███████╗██╗   ██╗'"$RESET"
  printf '%b\n' "$VIOLET"'██║    ██║██╔══██╗████╗  ██║╚══███╔╝╚██╗ ██╔╝'"$RESET"
  printf '%b\n' "$CYAN"'██║ █╗ ██║███████║██╔██╗ ██║  ███╔╝  ╚████╔╝ '"$RESET"
  printf '%b\n' "$VIOLET"'██║███╗██║██╔══██║██║╚██╗██║ ███╔╝    ╚██╔╝  '"$RESET"
  printf '%b\n' "$CYAN"'╚███╔███╔╝██║  ██║██║ ╚████║███████╗   ██║   '"$RESET"
  printf '%b\n' "$VIOLET"' ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   '"$RESET"
  printf '\n%b\n\n' "$WHITE$BOLD"'WANZY OFFICIAL  |  PTERODACTYL THEME MANAGER  v'"$VERSION$RESET"
  printf '%b\n' "$DIM"'────────────────────────────────────────────────────────────'"$RESET"
}

validate_panel() {
  [[ "$EUID" == 0 ]] || { fail "Jalankan dengan sudo/root."; exit 1; }
  [[ -d "$PANEL_DIR" && -f "$PANEL_DIR/artisan" && -f "$PANEL_DIR/composer.json" && -f "$PANEL_DIR/config/app.php" ]] || {
    fail "Pterodactyl tidak ditemukan/struktur tidak lengkap: $PANEL_DIR"; exit 1;
  }
  local version free_kib
  version="$(sed -nE "s/.*'version'[[:space:]]*=>[[:space:]]*['\"]([^'\"]+)['\"].*/\1/p" "$PANEL_DIR/config/app.php" | head -n1)"
  [[ "$version" =~ ^v?1\.[0-9]+\.[0-9]+([.-][[:alnum:].+-]+)?$ ]] || {
    fail "Versi panel bukan Pterodactyl v1.x yang dikenali."; exit 1;
  }
  free_kib="$(df -Pk "$PANEL_DIR" | awk 'NR==2 {print $4}')"
  [[ "$free_kib" =~ ^[0-9]+$ ]] && (( free_kib >= 1048576 )) || {
    fail "Minimal 1 GiB ruang kosong diperlukan."; exit 1;
  }
  ok "Pterodactyl $version terdeteksi; ruang disk cukup."
}

show_menu() {
  banner
  printf '%b\n\n' "$WHITE$BOLD"'PILIH TEMA'"$RESET"
  printf '  %b01%b  Stellar\n  %b02%b  Enigma\n  %b03%b  Elysium\n' "$CYAN" "$RESET" "$CYAN" "$RESET" "$CYAN" "$RESET"
  printf '  %b04%b  Frostcore\n  %b05%b  Nightcore\n  %b06%b  IceMinecraft\n  %b07%b  Noobe\n' "$CYAN" "$RESET" "$CYAN" "$RESET" "$CYAN" "$RESET" "$CYAN" "$RESET"
  printf '\n  %bX%b  Keluar\n\n' "$VIOLET" "$RESET"
}
select_theme() {
  local choice
  while true; do
    show_menu
    read -r -p "  Pilihan > " choice
    case "$(printf '%s' "$choice" | tr '[:upper:]' '[:lower:]')" in
      1|01) THEME_NAME="Stellar"; THEME_URL="$THEME_BASE/stellar.zip"; break ;;
      2|02) THEME_NAME="Enigma"; THEME_URL="$THEME_BASE/enigma.zip"; break ;;
      3|03) THEME_NAME="Elysium"; THEME_URL="$THEME_BASE/elysium.zip"; break ;;
      4|04) THEME_NAME="Frostcore"; THEME_URL="$THEME_BASE/frostcore.zip"; break ;;
      5|05) THEME_NAME="Nightcore"; THEME_URL="$THEME_BASE/nightcore.zip"; break ;;
      6|06) THEME_NAME="IceMinecraft"; THEME_URL="$THEME_BASE/iceMinecraft.zip"; break ;;
      7|07) THEME_NAME="Noobe"; THEME_URL="$THEME_BASE/noobe.zip"; break ;;
      x) exit 0 ;;
      *) warn "Pilihan tidak valid."; sleep 1 ;;
    esac
  done
}

prepare_archive() {
  mkdir -p "$BACKUP_ROOT"
  chmod 700 "$BACKUP_ROOT"
  TMP_DIR="$(mktemp -d /tmp/wanzy-theme.XXXXXX)"
  info "Mengunduh $THEME_NAME..."
  curl --fail --location --silent --show-error --retry 2 --connect-timeout 15 "$THEME_URL" -o "$TMP_DIR/theme.zip"
  [[ -s "$TMP_DIR/theme.zip" ]] || { fail "Arsip tema kosong."; return 1; }
  info "Memvalidasi dan mengekstrak arsip..."
  python3 - "$TMP_DIR/theme.zip" "$TMP_DIR/extracted" <<'PY'
import os, stat, sys, zipfile
from pathlib import Path, PurePosixPath
archive, target = sys.argv[1:3]
root = Path(target)
root.mkdir(mode=0o700, parents=True, exist_ok=False)
count = total = 0
with zipfile.ZipFile(archive) as zf:
    infos = zf.infolist()
    if len(infos) > 50000:
        raise SystemExit("Arsip memiliki terlalu banyak entri.")
    for item in infos:
        name = item.filename
        while name.startswith("./"):
            name = name[2:]
        p = PurePosixPath(name)
        if p.is_absolute() or not p.parts or any(x in ("", ".", "..") for x in p.parts):
            raise SystemExit(f"Path arsip tidak aman: {name}")
        if p.parts[0] != "pterodactyl" or len(p.parts) == 1 or item.is_dir():
            continue
        mode = (item.external_attr >> 16) & 0xFFFF
        if stat.S_ISLNK(mode) or (mode and not stat.S_ISREG(mode)):
            raise SystemExit(f"Symlink/jenis file tidak diizinkan: {name}")
        rel = p.parts[1:]
        if rel[0] == ".env" or rel[0] == "storage":
            continue
        total += item.file_size
        count += 1
        if total > 2 * 1024**3:
            raise SystemExit("Arsip melebihi batas 2 GiB.")
        out = root.joinpath(*rel)
        out.parent.mkdir(parents=True, exist_ok=True)
        with zf.open(item) as src, out.open("xb") as dst:
            copied = 0
            while True:
                chunk = src.read(1024 * 1024)
                if not chunk:
                    break
                copied += len(chunk)
                if copied > item.file_size:
                    raise SystemExit(f"Ukuran file tidak cocok: {name}")
                dst.write(chunk)
        if copied != item.file_size:
            raise SystemExit(f"File tidak lengkap: {name}")
        os.chmod(out, 0o644 | (mode & 0o111))
if not count:
    raise SystemExit("Tidak ditemukan file di folder pterodactyl/ pada arsip.")
print(f"{count} file tervalidasi ({total//1024} KiB).")
PY
  if find "$TMP_DIR/extracted" -path '*/database/migrations/*.php' -type f -print -quit | grep -q .; then
    fail "Tema membawa database migration. Installer tidak menjalankannya otomatis."
    return 1
  fi
  if find "$TMP_DIR/extracted" -type f \( -name package.json -o -name yarn.lock -o -name webpack.mix.js -o -name 'vite.config.*' -o -name '*.tsx' -o -name '*.jsx' -o -path '*/resources/*' \) -print -quit | grep -q .; then
    BUILD_REQUIRED=1
  fi
  if [[ "$THEME_NAME" == "Enigma" ]]; then
    local config="$TMP_DIR/extracted/resources/scripts/components/dashboard/DashboardContainer.tsx"
    [[ -f "$config" && ! -L "$config" ]] || { fail "File konfigurasi Enigma tidak ditemukan."; return 1; }
    printf '\n%bKonfigurasi link Enigma%b\n' "$VIOLET" "$RESET"
    read -r -p "  Link admin (https://): " LINK_ADMIN
    read -r -p "  Link channel (https://): " LINK_CHANNEL
    read -r -p "  Link grup (https://): " LINK_GROUP
    for link in "$LINK_ADMIN" "$LINK_CHANNEL" "$LINK_GROUP"; do
      [[ "$link" == https://* ]] || { fail "Semua link Enigma wajib diawali https://."; return 1; }
    done
    python3 - "$config" "$LINK_ADMIN" "$LINK_CHANNEL" "$LINK_GROUP" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
for old, new in zip(("LINK_ADMIN", "LINK_CHANNEL", "LINK_GROUP"), sys.argv[2:]):
    text = text.replace(old, new)
path.write_text(text)
PY
  fi
  ok "Paket lolos validasi."
}

apply_overlay() {
  BACKUP_DIR="$BACKUP_ROOT/$(date -u +%Y%m%dT%H%M%SZ)-$(printf '%s' "$THEME_NAME" | tr -cd '[:alnum:]_-')"
  mkdir -p "$BACKUP_DIR/files"
  chmod 700 "$BACKUP_DIR"
  info "Membuat backup file yang akan ditimpa..."
  python3 - "$PANEL_DIR" "$TMP_DIR/extracted" "$BACKUP_DIR" <<'PY'
import json, shutil, sys
from pathlib import Path
panel, source, backup = map(Path, sys.argv[1:])
entries = []
for src in sorted(p for p in source.rglob("*") if p.is_file()):
    rel = src.relative_to(source)
    dst = panel / rel
    cur = panel
    for part in rel.parts[:-1]:
        cur = cur / part
        if cur.is_symlink():
            raise SystemExit(f"Symlink tujuan ditolak: {cur}")
        if cur.exists() and not cur.is_dir():
            raise SystemExit(f"Tujuan bukan direktori: {cur}")
    if dst.is_symlink() or (dst.exists() and not dst.is_file()):
        raise SystemExit(f"Tujuan bukan file reguler: {dst}")
    existed = dst.exists()
    if existed:
        saved = backup / "files" / rel
        saved.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(dst, saved)
    entries.append({"path": rel.as_posix(), "existed": existed})
(backup / "manifest.json").write_text(json.dumps(entries, indent=2))
print(f"{len(entries)} file dicatat.")
PY
  if (( BUILD_REQUIRED )); then
    if [[ -d "$PANEL_DIR/public/assets" ]]; then
      cp -a "$PANEL_DIR/public/assets" "$BACKUP_DIR/public-assets"
      touch "$BACKUP_DIR/had-assets"
    else
      touch "$BACKUP_DIR/no-assets"
    fi
  fi
  info "Menerapkan overlay tema..."
  python3 - "$PANEL_DIR" "$TMP_DIR/extracted" "$BACKUP_DIR" <<'PY'
import json, shutil, sys
from pathlib import Path
panel, source, backup = map(Path, sys.argv[1:])
entries = json.loads((backup / "manifest.json").read_text())
try:
    for item in entries:
        rel = Path(item["path"])
        dst = panel / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.is_symlink():
            raise RuntimeError(f"Symlink tujuan ditolak: {dst}")
        shutil.copy2(source / rel, dst)
except Exception:
    for item in reversed(entries):
        rel = Path(item["path"])
        dst = panel / rel
        saved = backup / "files" / rel
        if item["existed"] and saved.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(saved, dst)
        elif not item["existed"]:
            dst.unlink(missing_ok=True)
    raise
print("Overlay berhasil diterapkan.")
PY
  while IFS= read -r -d '' file; do chown www-data:www-data "$file"; done < <(find "$TMP_DIR/extracted" -type f -print0)
}

rollback_overlay() {
  [[ -n "$BACKUP_DIR" && -f "$BACKUP_DIR/manifest.json" ]] || return 0
  warn "Build gagal; mengembalikan file yang diubah..."
  python3 - "$PANEL_DIR" "$BACKUP_DIR" <<'PY'
import json, shutil, sys
from pathlib import Path
panel, backup = map(Path, sys.argv[1:])
for item in reversed(json.loads((backup / "manifest.json").read_text())):
    rel = Path(item["path"])
    dst = panel / rel
    saved = backup / "files" / rel
    if item["existed"] and saved.exists():
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(saved, dst)
    elif not item["existed"]:
        dst.unlink(missing_ok=True)
assets = panel / "public/assets"
if (backup / "had-assets").exists():
    if assets.exists():
        shutil.rmtree(assets)
    shutil.copytree(backup / "public-assets", assets)
elif (backup / "no-assets").exists() and assets.exists():
    shutil.rmtree(assets)
print("Rollback overlay selesai.")
PY
}

build_and_clear() {
  cd "$PANEL_DIR"
  if (( BUILD_REQUIRED )); then
    command -v yarn >/dev/null 2>&1 || { fail "Yarn tidak ditemukan; source tema sudah dibackup."; return 1; }
    info "Menjalankan yarn install..."
    yarn install --non-interactive || return 1
    info "Membangun frontend..."
    yarn build:production || return 1
  fi
  php artisan optimize:clear
  php artisan view:clear
  local service
  service="$(systemctl list-units --type=service --all --no-legend 2>/dev/null | awk '$1 ~ /^php[0-9.]+-fpm\.service$/ {print $1; exit}')"
  [[ -z "$service" ]] || systemctl restart "$service"
}

install_theme() {
  banner
  printf '%bTema dipilih:%b %s\n\n' "$CYAN" "$RESET" "$THEME_NAME"
  warn "Source panel akan diubah. File yang tertimpa akan dibackup."
  read -r -p "  Lanjutkan? [y/N] " confirm
  [[ "$(printf '%s' "$confirm" | tr '[:upper:]' '[:lower:]')" == y ]] || { info "Dibatalkan."; return 0; }
  prepare_archive || return 1
  apply_overlay || return 1
  if ! build_and_clear; then
    rollback_overlay
    fail "Build gagal. File overlay dikembalikan. Backup: $BACKUP_DIR"
    return 1
  fi
  ok "Tema $THEME_NAME berhasil dipasang."
  ok "Backup tersimpan: $BACKUP_DIR"
  read -r -p "  Tekan Enter untuk kembali..."
}

main() {
  [[ "$EUID" == 0 ]] || { fail "Jalankan dengan sudo/root."; exit 1; }
  command -v curl >/dev/null 2>&1 || { fail "curl belum tersedia."; exit 1; }
  command -v python3 >/dev/null 2>&1 || { fail "python3 belum tersedia."; exit 1; }
  command -v php >/dev/null 2>&1 || { fail "php belum tersedia."; exit 1; }
  validate_panel
  while true; do
    select_theme
    install_theme || { warn "Instalasi gagal."; read -r -p "  Tekan Enter..."; }
  done
}
main "$@"
