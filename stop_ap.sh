#!/bin/bash

echo "===== Stopping Access Point and Restoring WiFi ====="

# 1. Stop hostapd and dnsmasq
echo "[1/6] Stopping services..."
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl stop dnsmasq 2>/dev/null || true
sudo pkill hostapd 2>/dev/null || true

# 2. Bring wlan0 down
echo "[2/6] Bringing wlan0 down..."
sudo ip link set wlan0 down 2>/dev/null || true

# 3. Remove the static IP address
echo "[3/6] Removing static IP..."
sudo ip addr flush dev wlan0 2>/dev/null || true

# 4. Reset WiFi driver modules (clean slate)
echo "[4/6] Resetting WiFi drivers..."
sudo rmmod iwlmvm 2>/dev/null || true
sudo rmmod iwlwifi 2>/dev/null || true
sudo rmmod mac80211 2>/dev/null || true
sudo rmmod cfg80211 2>/dev/null || true

# 5. Reload drivers
echo "[5/6] Reloading WiFi drivers..."
sudo modprobe iwlwifi
sleep 2  # Wait for interface to reappear

# 6. Set wlan0 back to managed mode and bring it up
echo "[6/6] Restoring wlan0 to managed mode..."
sudo nmcli device set wlan0 managed yes
sudo ip link set wlan0 up

# Disable IP forwarding
sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward"

# Flush iptables NAT rules
sudo iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
sudo iptables -D FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i wlan0 -o eth0 -j ACCEPT 2>/dev/null || true


echo "===== WiFi restored to client mode! ====="
echo "You can now connect to Wi-Fi networks using NetworkManager."
