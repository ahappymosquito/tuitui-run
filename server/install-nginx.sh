#!/usr/bin/env bash
# Run on the server as: sudo bash /home/ts3/tuitui-api/install-nginx.sh
set -euo pipefail
install -m 644 /home/ts3/tuitui-api/nginx-tuitui-api.conf /etc/nginx/snippets/tuitui-api.conf
snippet=/etc/nginx/snippets/love-book-proxy.conf
if ! grep -q 'tuitui-api' "$snippet"; then
  printf '\ninclude /etc/nginx/snippets/tuitui-api.conf;\n' >> "$snippet"
fi
nginx -t
systemctl reload nginx
echo "https://qrqto.club/tuitui-api/v1/health should now work"
