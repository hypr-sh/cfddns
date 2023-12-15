#!/usr/bin/env bash
set -euo pipefail

[ $# -lt 2 ] && { echo "Usage: cfddns <record> <token>"; exit 1 ; }

REC="${1}"
TOKEN="${2}"
CURRENT=$(curl -sH 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=${1}&type=A" | jq -r .Answer[0].data)
IP=$(curl -s -X GET https://checkip.amazonaws.com)
ZONE=$(echo ${REC} | awk -F. '{ print $(NF-1)"."$NF }')

if [[ ${IP} == ${CURRENT} ]]; then
  echo "OK: current record still valid"
  exit 0
fi

ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${ZONE}" \
-H "Authorization: Bearer ${TOKEN}" -H "Content-Type:application/json" | jq -r '{"result"}[] | .[0] | .id')

REC_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${REC}" \
-H "Authorization: Bearer ${TOKEN}" -H "Content-Type:application/json" | jq -r '{"result"}[] | .[0] | .id')

UPDATE=$(curl --fail-with-body -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${REC_ID}" \
-H "Authorization: Bearer ${TOKEN}" \
-H "Content-Type: application/json" \
--data "{\"type\":\"A\",\"name\":\"${REC}\",\"content\":\"${IP}\",\"ttl\":1,\"proxied\":false}")

# check errors
if [ "$?" -ne "0" ]; then
  ERROR=$(echo ${UPDATE} | jq -r '{"errors"}[] | .[0] | .message')
  echo "ERROR: could not update record: ${ERROR}"
  exit 1
fi

echo "OK: record value update to: ${IP}"
