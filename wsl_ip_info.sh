#!/bin/bash
# WSL IP Information Display Script
#
# Displays network configuration information for WSL2, including WSL IP address,
# Windows host IP address, and network interface details. This is particularly
# useful for configuring services, firewalls, or understanding WSL2 networking.
#
# Features:
# - Shows WSL2 instance IP address
# - Displays Windows host IP address (as seen from WSL)
# - Lists all network interfaces and their IPs
# - Shows DNS server configuration
# - Useful for debugging network issues and configuring cross-platform services
#
# In WSL2, the instance gets its own IP on a virtual network, and the Windows
# host is accessible via a gateway IP. This information is essential when:
# - Configuring firewall rules
# - Setting up development servers accessible from Windows
# - Troubleshooting network connectivity issues
# - Configuring database connections between WSL and Windows applications
#
# Usage:
# $ ./wsl_ip_info.sh
# $ chmod +x ~/wsl_ip_info.sh

echo "--- 🌐 WSL2 Network Information ---"
echo ""

# Get WSL IP address (primary interface, usually eth0)
WSL_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)

if [ -n "$WSL_IP" ]; then
    echo "📍 WSL2 IP Address:"
    echo "   $WSL_IP"
else
    echo "⚠️  Could not determine WSL2 IP address"
fi

echo ""

# Get Windows Host IP (gateway)
HOST_IP=$(ip route show default | awk '{print $3}')

if [ -n "$HOST_IP" ]; then
    echo "🖥️  Windows Host IP (Gateway):"
    echo "   $HOST_IP"
else
    echo "⚠️  Could not determine Windows Host IP"
fi

echo ""

# Show all network interfaces
echo "🔌 Network Interfaces:"
ip -brief addr show | while read -r line; do
    echo "   $line"
done

echo ""

# Show DNS servers
echo "🌍 DNS Servers:"
if [ -f /etc/resolv.conf ]; then
    grep "^nameserver" /etc/resolv.conf | while read -r ns ip; do
        echo "   $ip"
    done
else
    echo "   Could not read /etc/resolv.conf"
fi

echo ""

# Show helpful connection examples
if [ -n "$WSL_IP" ]; then
    echo "--- 📋 Connection Examples ---"
    echo ""
    echo "From Windows to WSL service:"
    echo "  http://$WSL_IP:3000"
    echo "  postgresql://$WSL_IP:5432"
    echo ""
fi

if [ -n "$HOST_IP" ]; then
    echo "From WSL to Windows service:"
    echo "  http://$HOST_IP:8080"
    echo "  Use 'localhost' or '127.0.0.1' may NOT work - use $HOST_IP instead"
    echo ""
fi

# Show hostname
echo "🏷️  Hostname: $(hostname)"
echo ""

# Optional: Test connectivity to Windows host
echo "--- 🔍 Connectivity Test ---"
if [ -n "$HOST_IP" ]; then
    if ping -c 1 -W 1 "$HOST_IP" &> /dev/null; then
        echo "✅ Can reach Windows host ($HOST_IP)"
    else
        echo "❌ Cannot reach Windows host ($HOST_IP)"
    fi
fi

# Test external connectivity
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
    echo "✅ External network connectivity OK"
else
    echo "❌ No external network connectivity"
fi

echo ""
