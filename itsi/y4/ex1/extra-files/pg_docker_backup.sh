#!/bin/sh
set -eu

CONTAINER="app-db-1"
PG_USER="postgres"
PG_DB="someApp"
BACKUP_DIR="/mnt/backups/app"
GPG_RECIPIENT="ex1-itsi"
LOGFILE="/var/log/pg_docker_backup.log"

STAMP=$(date +"%Y%m%d_%H%M%S")
DUMPFILE="${BACKUP_DIR}/db_snapshot_${STAMP}.sql"
ENCRYPTED="${DUMPFILE}.gpg"

log() { echo "$(date '+%F %T') [$1] $2" >> "$LOGFILE"; }

log INFO "Starting Dockerized Postgres backup"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    log ERROR "Container '${CONTAINER}' not running"
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    log ERROR "Backup directory missing or not mounted: $BACKUP_DIR"
    exit 1
fi

if docker exec "$CONTAINER" pg_dump -U "$PG_USER" "$PG_DB" > "$DUMPFILE" 2>>"$LOGFILE"; then
    log INFO "Dump created: $(basename "$DUMPFILE")"
else
    log ERROR "pg_dump failed"
    rm -f "$DUMPFILE"
    exit 1
fi

if gpg --homedir /home/fus-admin/.gnupg --batch --yes --recipient "$GPG_RECIPIENT" --encrypt "$DUMPFILE" 2>>"$LOGFILE"; then
    log INFO "Encrypted: $(basename "$ENCRYPTED")"
    rm -f "$DUMPFILE"
else
    log ERROR "GPG encryption failed"
    rm -f "$DUMPFILE"
    exit 2
fi

log INFO "Backup completed successfully."
exit 0
