#!/bin/sh
# Creates the app buckets and keys listed in buckets.json. Safe to re-run: existing keys and
# buckets are kept, permissions and CORS are (re)applied. Runs as an Argo CD PostSync hook
# (bucket-provisioner.yaml).
#
# Each entry: bucket, keyId (GK + 24 hex, also referenced by the app's manifests), keyName,
# secret (a Bitwarden key, mounted as a file under $KEYS_DIR), optional corsOrigins.
set -eu

ADMIN="${GARAGE_ADMIN_URL:-http://garage.garage.svc.cluster.local:3903}"
S3="${GARAGE_S3_URL:-http://garage.garage.svc.cluster.local:3900}"
REGION="${GARAGE_S3_REGION:-us-east-1}" # must equal s3_region in garage.toml
CONFIG="${BUCKETS_CONFIG:-/config/buckets.json}"
KEYS_DIR="${KEYS_DIR:-/keys}"

api() { # method endpoint [json]
  curl -fsS -X "$1" -H "Authorization: Bearer $GARAGE_ADMIN_TOKEN" -H "Content-Type: application/json" \
    "$ADMIN/v2/$2" ${3:+--data "$3"}
}

until api GET GetClusterHealth >/dev/null 2>&1; do echo "waiting for garage"; sleep 2; done

jq -c '.[]' "$CONFIG" | while read -r entry; do
  get() { printf '%s' "$entry" | jq -r "$1"; }
  bucket=$(get .bucket)
  key_id=$(get .keyId)
  key_name=$(get .keyName)
  secret_file="$KEYS_DIR/$(get .secret)"
  [ -s "$secret_file" ] || { echo "error: $bucket: missing secret $secret_file" >&2; exit 1; }
  secret=$(cat "$secret_file")

  if ! api GET "GetKeyInfo?id=$key_id" >/dev/null 2>&1; then
    api POST ImportKey "$(jq -n --arg id "$key_id" --arg s "$secret" --arg n "$key_name" \
      '{accessKeyId: $id, secretAccessKey: $s, name: $n}')" >/dev/null
    echo "$bucket: key $key_name imported"
  fi

  bucket_id=$(api GET "GetBucketInfo?globalAlias=$bucket" 2>/dev/null | jq -r '.id // empty' || true)
  if [ -z "$bucket_id" ]; then
    bucket_id=$(api POST CreateBucket "$(jq -n --arg b "$bucket" '{globalAlias: $b}')" | jq -r .id)
    echo "$bucket: bucket created"
  fi

  api POST AllowBucketKey "$(jq -n --arg b "$bucket_id" --arg k "$key_id" \
    '{bucketId: $b, accessKeyId: $k, permissions: {read: true, write: true, owner: true}}')" >/dev/null

  # Browsers upload with presigned URLs, so public buckets need CORS for the app's origin.
  origins=$(get '.corsOrigins // [] | map("<AllowedOrigin>\(.)</AllowedOrigin>") | join("")')
  if [ -n "$origins" ]; then
    cors="<CORSConfiguration><CORSRule>$origins<AllowedMethod>GET</AllowedMethod><AllowedMethod>PUT</AllowedMethod><AllowedMethod>HEAD</AllowedMethod><AllowedHeader>*</AllowedHeader><ExposeHeader>ETag</ExposeHeader><MaxAgeSeconds>3600</MaxAgeSeconds></CORSRule></CORSConfiguration>"
    curl -fsS -X PUT --aws-sigv4 "aws:amz:$REGION:s3" --user "$key_id:$secret" \
      -H "Content-MD5: $(printf '%s' "$cors" | openssl md5 -binary | base64)" \
      -H "Content-Type: application/xml" --data-binary "$cors" "$S3/$bucket?cors" >/dev/null
  fi
  echo "$bucket: ok"
done
