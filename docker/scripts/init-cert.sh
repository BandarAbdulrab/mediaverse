#!/usr/bin/env bash
# Usage: ./init-cert.sh origin.example.com admin@example.com
set -euo pipefail

DOMAIN="${1:?origin domain required}"
EMAIL="${2:?email required}"

cd "$(dirname "$0")/.."          # docker/
sudo mkdir -p /var/www/certbot

# 1) HTTP-only config so Nginx can start without certificates
sed "s/ORIGIN_DOMAIN/${DOMAIN}/g" nginx/http-only.conf > nginx/conf.d/mediaverse.conf
docker compose up -d
docker compose exec nginx nginx -t

# 2) Issue the certificate through Nginx on port 80 (no stopping, no conflict)
sudo certbot certonly --webroot -w /var/www/certbot \
    -d "${DOMAIN}" --agree-tos -m "${EMAIL}" --non-interactive

# 3) Switch to the full HTTPS config and reload
sed "s/ORIGIN_DOMAIN/${DOMAIN}/g" nginx/https.conf > nginx/conf.d/mediaverse.conf
docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload

# 4) Reload Nginx automatically after every renewal
sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh >/dev/null <<'HOOK'
#!/usr/bin/env bash
docker exec mediaverse_proxy nginx -s reload
HOOK
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

echo "Done. Test: curl -I https://${DOMAIN}"