#!/bin/bash

HOME_GNS3=$(sudo -u gns3 bash -c 'echo $HOME')
SSL_PATH="$HOME_GNS3/.config/GNS3/ssl"
CERT_FILE="$SSL_PATH/server.cert"
KEY_FILE="$SSL_PATH/server.key"
RENEW_SCRIPT="$HOME_GNS3/renew-script.sh"
mkdir -p "$SSL_PATH"

sudo -u gns3 bash -c "
  openssl req -new -x509 -days 365 -nodes \
    -out '$CERT_FILE' \
    -keyout '$KEY_FILE' \
    -subj '/C=AT/ST=Vienna/L=Vienna/O=HTL-Donaustadt/OU=3AHITN/CN=nwt-lab/emailAddress=jx62vdws6@mozmail.com'
"

sed -i "/\[Server\]/a certfile=${CERT_FILE}\ncertkey=${KEY_FILE}\nssl=True" /etc/gns3/gns3_server.conf

sudo sh -c "echo '0 0 $(date +\%d) $(date -d '+364 days' +\%m) * /bin/bash $RENEW_SCRIPT' | crontab -u gns3 -"

cat << EOF > "$RENEW_SCRIPT"
#!/bin/bash

rm "$CERT_FILE" "$KEY_FILE"

openssl req -new -x509 -days 365 -nodes \
    -out '$CERT_FILE' \
    -keyout '$KEY_FILE' \
    -subj '/C=AT/ST=Vienna/L=Vienna/O=HTL-Donaustadt/OU=3AHITN/CN=nwt-lab/emailAddress=jx62vdws6@mozmail.com'

EOF

echo "Done :3"
