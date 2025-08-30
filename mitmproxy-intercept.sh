#!/usr/bin/bash

set -u

MITM_PORT=8181
MITM_USER=mitmproxyuser

TARGET=${2:-both} # default: intercept both HTTP & HTTPS

STATE_DIR=/tmp/mitmproxy-intercept
IPV4_FORWARD_STATE_FILE=$STATE_DIR/ipv4_forward_state
IPV6_FORWARD_STATE_FILE=$STATE_DIR/ipv6_forward_state
MITM_WEB_PID_FILE=$STATE_DIR/mitmweb_pid

start_proxy() {
    mkdir -p $STATE_DIR

    echo "[+] Saving current IP forwarding state..."
    sysctl net.ipv4.ip_forward | awk '{print $3}' > $IPV4_FORWARD_STATE_FILE
    sysctl net.ipv6.conf.all.forwarding | awk '{print $3}' > $IPV6_FORWARD_STATE_FILE

    echo "[+] Enabling IP forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo sysctl -w net.ipv6.conf.all.forwarding=1

    echo "[+] Disable ICMP redirects..."
    sudo sysctl -w net.ipv4.conf.all.send_redirects=0

    case "$TARGET" in
        http)
            echo "[+] Redirecting HTTP (port 80) traffic to mitmproxy..."
            sudo iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 80 -j REDIRECT --to-port $MITM_PORT
            sudo ip6tables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 80 -j REDIRECT --to-port $MITM_PORT
            ;;
        https)
            echo "[+] Redirecting HTTPS (port 443) traffic to mitmproxy..."
            sudo iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 443 -j REDIRECT --to-port $MITM_PORT
            sudo ip6tables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 443 -j REDIRECT --to-port $MITM_PORT
            ;;
        both)
            echo "[+] Redirecting HTTP (port 80) and HTTPS (port 443) traffic to mitmproxy..."
            sudo iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 80 -j REDIRECT --to-port $MITM_PORT
            sudo iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 443 -j REDIRECT --to-port $MITM_PORT
            
            sudo ip6tables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 80 -j REDIRECT --to-port $MITM_PORT
            sudo ip6tables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 443 -j REDIRECT --to-port $MITM_PORT
            ;;
        *)
            echo "Invalid option: $TARGET"
            echo "Usage: $0 start [http|https|both]"
            exit 1
            ;;
    esac

    echo "[+] Starting mitmproxy on port $MITM_PORT..."

    # Use exec otherwise $! may return the process ID of the bash shell instead of the mitmweb process
    sudo -u mitmproxyuser -H bash -c 'exec $HOME/.local/bin/mitmweb --mode transparent --showhost --set block_global=false --listen-port 8181' &
    
    MITM_PID=$!
    echo "[+] mitproxy started. Process ID: $MITM_PID"
    echo $MITM_PID > $MITM_WEB_PID_FILE
}

stop_proxy() {
    echo "[+] Stopping mitmweb..."
    kill $(cat $MITM_WEB_PID_FILE)

    echo "[+] Removing iptables rules..."
    sudo iptables -t nat -D OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 80  -j REDIRECT --to-port $MITM_PORT 2>/dev/null || true
    sudo iptables -t nat -D OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 443 -j REDIRECT --to-port $MITM_PORT 2>/dev/null || true
    sudo ip6tables -t nat -D OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 80  -j REDIRECT --to-port $MITM_PORT 2>/dev/null || true
    sudo ip6tables -t nat -D OUTPUT -p tcp -m owner ! --uid-owner $MITM_USER --dport 443 -j REDIRECT --to-port $MITM_PORT 2>/dev/null || true

    echo "[+] Restoring previous IPv4 forwarding state..."
    if [[ -f $IPV4_FORWARD_STATE_FILE ]]; then
        OLD_STATE=$(cat $IPV4_FORWARD_STATE_FILE)
        sudo sysctl -w net.ipv4.ip_forward=$OLD_STATE >/dev/null
    else
        echo "[!] Warning: no saved IPv4 state found, leaving net.ipv4.ip_forward unchanged."
    fi

    echo "[+] Restoring previous IPv6 forwarding state..."
    if [[ -f $IPV6_FORWARD_STATE_FILE ]]; then
        OLD_STATE=$(cat $IPV6_FORWARD_STATE_FILE)
        sudo sysctl -w net.ipv6.conf.all.forwarding=1=$OLD_STATE >/dev/null
    else
        echo "[!] Warning: no saved IPv6 state found, leaving net.ipv6.conf.all.forwarding unchanged."
    fi

    rm -rf $STATE_DIR

    echo "[+] Re-enable ICMP redirects..."
    sudo sysctl -w net.ipv4.conf.all.send_redirects=1

    echo "[+] Mitmproxy interception disabled."
}

case "$1" in
    start)
        start_proxy
        ;;
    stop)
        stop_proxy
        ;;
    *)
        echo "Usage: $0 {start|stop} [http|https|both]"
        exit 1
        ;;
esac
