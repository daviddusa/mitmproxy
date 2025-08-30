#!/usr/bin/bash

set -eu

USER=mitmproxyuser
HTTPS_SETUP_GUIDE="$(cat <<'EOF'
For intercepting HTTPS traffic do the following:

1. Configure HTTP proxy at the OS level for port 8181.
2. Open http://mitm.it
3. Download the mitmproxy-ca-cert.pem
4. Run `add-mitmproxy-cert.sh`
5. Run `mitmproxy-intercept.sh start`
6. When you no longer need the cert run `rm-mitmproxy-cert.sh

https://docs.mitmproxy.org/stable/concepts/certificates/#quick-setup
EOF
)"

setup() {
    echo "Setting up $USER..."
    sudo useradd --create-home $USER

    echo "Installing mitmproxy..."
    sudo -u mitmproxyuser -H bash -c 'cd ~ && pip3 install --user mitmproxy'

    echo "Installed mitmproxy successfully."
    sudo -u mitmproxyuser -H bash -c '$HOME/.local/bin/mitmproxy --version'

    echo "Setup finished."
    echo "${HTTPS_SETUP_GUIDE}"
}

teardown() {
    echo "Removing $USER..."
    sudo userdel $USER
    sudo rm -rf /home/$USER
}

case "$1" in
    setup)
        setup
        ;;
    teardown)
        teardown
        ;;
    *)
        echo "Usage: $0 {setup|teardown}"
        exit 1
        ;;
esac
