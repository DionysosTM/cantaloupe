#!/bin/sh
set -e

HOST="iiif-minio"
PORT=9000
USER="${MINIO_ROOT_USER:-minio}"
PASS="${MINIO_ROOT_PASSWORD:-minio123}"

echo "⏳ Attente de MinIO à $HOST:$PORT…"
until nc -z "$HOST" "$PORT"; do
  echo "🕐 MinIO pas encore prêt…"
  sleep 2
done
echo "✅ MinIO est prêt"

# Alias mc
mc alias set local http://$HOST:$PORT "$USER" "$PASS"

# Buckets à créer
for B in images tiles cache ; do
  mc mb -p local/$B || true
done
mc anonymous set download local/images

echo "✅ Buckets créés (ou déjà existants)"
