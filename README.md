# Linux Wi-Fi Access Point Scripts

Easily turn your Linux machine into a Wi-Fi Access Point (AP) with internet sharing using `start_ap.sh` and `stop_ap.sh`.  
These scripts handle Wi-Fi driver reset, static IP configuration, NAT setup, IP forwarding, and foreground hostapd management.

---

## **Contents**

- `start_ap.sh` – Starts the AP, configures static IP, enables NAT, and launches hostapd.  
- `stop_ap.sh` – Stops the AP, disables NAT/IP forwarding, and restores Wi-Fi to client mode.  

---

## **Prerequisites**

### 1. Linux Distribution
- Tested on Debian-based distributions (e.g., Kali Linux).  
- Requires NetworkManager installed.

### 2. Wi-Fi Adapter
- Must support **AP / Master mode**:

```bash
iw list | grep -A 10 "Supported interface modes"
````

* Ensure `* AP` appears.
* Default interface in scripts: `wlan0`. Adjust if different.

### 3. Required Packages

```bash
sudo apt update
sudo apt install -y hostapd dnsmasq iptables iproute2 network-manager
```

* `hostapd` – creates the AP
* `dnsmasq` – DHCP/DNS server
* `iptables` – NAT/forwarding
* `network-manager` – manages Wi-Fi interfaces

---

## **Configuration**

### 1. Wi-Fi Interface

* If your Wi-Fi interface is not `wlan0`, edit `start_ap.sh` near the top and replace the default interface with your own, e.g.:

```bash
INTERFACE="wlan0"  # replace wlp2s0 with your actual Wi-Fi interface
```

* Update all occurrences of `$INTERFACE` in the script.

---

### 2. WAN Interface

* Default NAT assumes `eth0`.
* If your internet interface is different, edit the script or use dynamic detection:

```bash
WAN_IF=$(ip route | grep '^default' | awk '{print $5}')
```

---

### 3. Static IP

* Default AP IP: `192.168.4.1/24`.
* Change in `start_ap.sh` if necessary:

---

### 4. hostapd Configuration

* Create or edit the hostapd config:

```bash
sudo nano /etc/hostapd/hostapd.conf
```

* Add:

```text
interface=wlan0
driver=nl80211
ssid=MyAccessPoint
hw_mode=g
channel=6
auth_algs=1
wmm_enabled=1
wpa=2
wpa_passphrase=MyStrongPassword
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
```

* Replace `ssid` and `wpa_passphrase` with your own values.

---

### 5. Point hostapd to this config

* Edit `/etc/default/hostapd`:

```bash
sudo nano /etc/default/hostapd
```

* Add or edit the line:

```text
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

* Save and exit.

---

### 6. Persist iptables (Optional)

* Install persistence package:

```bash
sudo apt install -y iptables-persistent
```

* After the **first successful run** of `start_ap.sh`, save iptables rules:

```bash
sudo sh -c "iptables-save > /etc/iptables/rules.v4"
```

> Do not include this command in the start script—it only needs to be run once.

---

## **Usage**

```bash
# Start the AP
sudo ./start_ap.sh

# Stop the AP
sudo ./stop_ap.sh
```

* Run `start_ap.sh` in a terminal to see hostapd logs.
* Use `Ctrl+C` to stop hostapd manually before running `stop_ap.sh`.

---

