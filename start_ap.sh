#!/bin/bash

# Exit immediately if any command fails
set -e

echo "===== Starting Access Point Setup ====="

# 1. STOP ANY CONFLICTING SERVICES
echo "[1/8] Stopping conflicting services..."
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl stop wpa_supplicant 2>/dev/null || true
sudo pkill wpa_supplicant 2>/dev/null || true
sudo pkill hostapd 2>/dev/null || true

# 2. BRING INTERFACE DOWN (if it exists)
echo "[2/8] Bringing wlan0 down..."
sudo ip link set wlan0 down 2>/dev/null || true

# 3. RESET WIFI DRIVER MODULES (THE KEY FIX)
echo "[3/8] Resetting WiFi driver modules..."
sudo rmmod iwlmvm 2>/dev/null || true
sudo rmmod iwlwifi 2>/dev/null || true
sudo rmmod mac80211 2>/dev/null || true
sudo rmmod cfg80211 2>/dev/null || true

# 4. RELOAD DRIVER MODULES
echo "[4/8] Reloading WiFi driver modules..."
sudo modprobe iwlwifi

# 5. WAIT FOR WLAN0 INTERFACE TO REAPPEAR
echo "[5/8] Waiting for wlan0 interface to be detected..."
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
    if ip link show wlan0 >/dev/null 2>&1; then
        echo "wlan0 interface detected!"
        break
    fi
    echo "Attempt $attempt/$max_attempts: wlan0 not ready yet, waiting..."
    sleep 1
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo "ERROR: wlan0 interface did not appear after $max_attempts seconds"
    echo "Trying to continue anyway..."
fi

# 6. BRING INTERFACE UP AND SET UNMANAGED
echo "[6/8] Bringing wlan0 up and setting unmanaged..."
sudo ip link set wlan0 up
sleep 2  # Give the interface time to initialize
sudo nmcli device set wlan0 managed no

# 7. ASSIGN STATIC IP ADDRESS
echo "[7/8] Assigning static IP address..."
sudo ip addr flush dev wlan0 2>/dev/null || true
sudo ip addr add 192.168.4.1/24 dev wlan0

# 7.1 ENABLE IP FORWARDING AND SETUP NAT
echo "[7.1/8] Enabling IP forwarding and setting up NAT..."
# Enable IP forwarding
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# Set up iptables for NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

# Optional: Show the rules for verification
sudo iptables -t nat -L -v
sudo iptables -L -v


# 8. START DNSMASQ AND THEN HOSTAPD IN FOREGROUND
echo "[8/8] Starting dnsmasq and then hostapd in foreground..."
sudo systemctl start dnsmasq

echo "===== Starting hostapd in foreground (Ctrl+C to stop) ====="
echo "SSID: $(grep '^ssid=' /etc/hostapd/hostapd.conf | cut -d'=' -f2)"
echo "Gateway IP: 192.168.4.1"
echo "DHCP Range: 192.168.4.2 - 192.168.4.20"
echo "=========================================================="

# Start hostapd in foreground - this will keep the terminal occupied
sudo hostapd /etc/hostapd/hostapd.conf
