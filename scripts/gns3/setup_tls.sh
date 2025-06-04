#!/usr/bin/env bash
set -euo pipefail

# 1) require root or passwordless sudo
if [ "$EUID" -ne 0 ] && ! sudo -n true &>/dev/null; then
  echo "Error: must be root or have passwordless sudo" >&2
  exit 1
fi

# If not root, use sudo (we know it’s passwordless)
SUDO=""
if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
fi

# make apt non-interactive
export DEBIAN_FRONTEND=noninteractive

# cert subject
SUBJ='/C=AT/ST=Vienna/L=Vienna/O=HTL-Donaustadt/OU=3AHITN\
/CN=nwt-lab/emailAddress=jx62vdws6@mozmail.com'

# 2) install deps
$SUDO apt-get update -qq
$SUDO apt-get install -y -q \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  debian-keyring debian-archive-keyring \
  apt-transport-https curl gnupg

# 3) remove any stale keyring, then import Caddy’s GPG key
KEYRING=/usr/share/keyrings/caddy-stable-archive-keyring.gpg
$SUDO rm -f "$KEYRING"
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | gpg --batch --dearmor \
    -o /tmp/caddy.gpg
$SUDO mv /tmp/caddy.gpg "$KEYRING"

# 4) add repo
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | $SUDO tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null

# 5) install Caddy
$SUDO apt-get update -qq
$SUDO apt-get install -y -q caddy

# 6) generate cert
CERT_DIR=/etc/caddy/certs
$SUDO mkdir -p "$CERT_DIR"
$SUDO openssl req -new -x509 -days 365 -nodes \
  -out "$CERT_DIR/gns3.cert" \
  -keyout "$CERT_DIR/gns3.key" \
  -subj "$SUBJ"
$SUDO chown -R caddy:caddy "$CERT_DIR"

# 7) write Caddyfile
$SUDO tee /etc/caddy/Caddyfile >/dev/null <<EOF
:443 {
    reverse_proxy 127.0.0.1:3080
    tls $CERT_DIR/gns3.cert $CERT_DIR/gns3.key
}
EOF

# 8) enable & start Caddy
$SUDO systemctl enable caddy
$SUDO systemctl restart caddy

# 9) create renew script
RENEW=/usr/local/bin/renew-caddy-gns3-cert.sh
$SUDO tee "$RENEW" >/dev/null <<'EOL'
#!/usr/bin/env bash
set -euo pipefail
CERT_DIR=/etc/caddy/certs
openssl req -new -x509 -days 365 -nodes \
  -out "$CERT_DIR/gns3.cert" \
  -keyout "$CERT_DIR/gns3.key" \
  -subj '\'''"$SUBJ"'\'''
chown caddy:caddy "$CERT_DIR/gns3.cert" "$CERT_DIR/gns3.key"
systemctl reload caddy
EOL
$SUDO chmod +x "$RENEW"

# 10) schedule cron renewal
CRON_DAY=$(date +%-d)
CRON_MONTH=$(date -d '+364 days' +%-m)
CRON_JOB="0 0 $CRON_DAY $CRON_MONTH * /bin/bash $RENEW"
( $SUDO crontab -l 2>/dev/null; echo "$CRON_JOB" ) | $SUDO crontab -

echo "Caddy installed, cert generated, cron job added:"
echo "   $CRON_JOB"
