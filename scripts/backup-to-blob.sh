#!/usr/bin/env bash
#
# Backs the web root up to Azure Blob Storage and keeps the last 7 copies.
#
# On the VM:
#   sudo install -m 0755 backup-to-blob.sh /opt/scripts/backup-to-blob.sh
#   sudo crontab -e
#   0 2 * * * /opt/scripts/backup-to-blob.sh >> /var/log/weblab-backup.log 2>&1
#
# The SAS token is read from /etc/weblab-backup.env (chmod 600, root only) so that
# no credential is ever written into this script or into the crontab.

set -Eeuo pipefail

SOURCE_DIR="${SOURCE_DIR:-/var/www/html}"
STAGING_DIR="${STAGING_DIR:-/var/backups/weblab}"
KEEP_COPIES="${KEEP_COPIES:-7}"
ENV_FILE="${ENV_FILE:-/etc/weblab-backup.env}"

log() { printf '%s  %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"; }

trap 'log "FAILED at line $LINENO"' ERR

if [[ ! -r "$ENV_FILE" ]]; then
  log "ERROR: $ENV_FILE is missing. It must define STORAGE_ACCOUNT, CONTAINER and SAS_TOKEN."
  exit 1
fi

# shellcheck source=/dev/null
source "$ENV_FILE"

: "${STORAGE_ACCOUNT:?STORAGE_ACCOUNT is not set in $ENV_FILE}"
: "${CONTAINER:?CONTAINER is not set in $ENV_FILE}"
: "${SAS_TOKEN:?SAS_TOKEN is not set in $ENV_FILE}"

mkdir -p "$STAGING_DIR"

STAMP="$(date -u '+%Y%m%d-%H%M')"
ARCHIVE="$STAGING_DIR/webroot-$STAMP.tar.gz"

log "Creating $ARCHIVE from $SOURCE_DIR"
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

SIZE="$(du -h "$ARCHIVE" | cut -f1)"
log "Archive created, size $SIZE"

log "Uploading to https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER/"
azcopy copy "$ARCHIVE" \
  "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER/?$SAS_TOKEN" \
  --log-level ERROR

log "Upload finished"

# Local rotation: keep the newest $KEEP_COPIES archives, delete the rest.
mapfile -t OLD < <(find "$STAGING_DIR" -maxdepth 1 -name 'webroot-*.tar.gz' -printf '%T@ %p\n' |
                   sort -rn | tail -n "+$((KEEP_COPIES + 1))" | cut -d' ' -f2-)

if ((${#OLD[@]})); then
  log "Removing ${#OLD[@]} archive(s) older than the newest $KEEP_COPIES"
  printf '%s\n' "${OLD[@]}" | xargs -r rm -f
else
  log "Nothing to rotate (${KEEP_COPIES} or fewer archives kept)"
fi

log "Backup complete"
