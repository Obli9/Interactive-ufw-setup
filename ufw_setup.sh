#!/usr/bin/env bash

# ==============================================================================
# Script Name: ufw-hardener-interactive.sh
# Description: Interactive UFW firewall hardening and rule configuration script
# Requirement: Must be run as root
# ==============================================================================

set -euo pipefail

# Check for root privilege
if [[ $EUID -ne 0 ]]; then
   echo "[-] Error: This script must be run as root (sudo)." >&2
   exit 1
fi

echo "=================================================="
echo "          Interactive UFW Hardening               "
echo "=================================================="

# 1. Reset and Set Base Policies
read -rp "[?] Reset UFW to clean default state? (y/N): " RESET_CONFIRM
if [[ "${RESET_CONFIRM,,}" =~ ^(yes|y)$ ]]; then
    echo "[+] Resetting UFW..."
    ufw --force reset
fi

echo "[+] Applying default baseline (Deny Incoming, Allow Outgoing)..."
ufw default deny incoming
ufw default allow outgoing

# 2. Configure SSH (Rate Limited)
read -rp "[?] Do you want to enable SSH access? (Y/n): " ENABLE_SSH
if [[ ! "${ENABLE_SSH,,}" =~ ^(no|n)$ ]]; then
    read -rp "    -> Enter SSH port (default 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}
    echo "[+] Rate-limiting SSH on port $SSH_PORT..."
    ufw limit "$SSH_PORT"/tcp comment 'SSH Rate Limited'
fi

# 3. Prompt for Custom Open Ports
echo ""
echo "[+] --- Custom Open Ports ---"
read -rp "[?] Enter ports to ALLOW (space-separated, e.g., 80/tcp 443/tcp 53/udp) or press Enter to skip: " -a ALLOWED_PORTS

for PORT in "${ALLOWED_PORTS[@]}"; do
    if [[ -n "$PORT" ]]; then
        echo "[+] Allowing $PORT..."
        ufw allow "$PORT" comment 'Allowed Custom Port'
    fi
done

# 4. Prompt for Specific Blocked IPs or Subnets
echo ""
echo "[+] --- IP Blocking ---"
read -rp "[?] Enter IP addresses or subnets to BLOCK (space-separated, e.g., 192.168.1.50 203.0.113.0/24) or press Enter to skip: " -a BLOCKED_IPS

for IP in "${BLOCKED_IPS[@]}"; do
    if [[ -n "$IP" ]]; then
        echo "[+] Blocking traffic from $IP..."
        ufw insert 1 deny from "$IP" comment 'Blocked IP/Subnet'
    fi
done

# 5. Enable Logging level
echo ""
echo "[+] Setting logging level to medium..."
ufw logging medium

# 6. Enable UFW
echo ""
echo "[+] Enabling UFW..."
ufw --force enable

# 7. Final Output
echo ""
echo "[+] UFW Configuration completed. Active Rules:"
echo "--------------------------------------------------"
ufw status verbose numbered
