sudo mkdir -p /usr/local/share/ca-certificates/extra
# sudo cp mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/extra/mitmproxy-ca-cert.crt
sudo cp /home/mitmproxyuser/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/extra/mitmproxy-ca-cert.crt
sudo update-ca-certificates --fresh
