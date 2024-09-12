#!/bin/bash

# Remove old sources
rm /etc/apt/sources.list.d/*
echo -e "\e[32mRemoved sources.list.d dir contents\e[0m"
rm /etc/apt/sources.list
echo -e "\e[32mRemoved sources.list\e[0m"

# Create a new sources.list
touch /etc/apt/sources.list
echo -e "\e[32mCreated new sources.list\e[0m"

# Populate sources.list with new entries
cat <<EOF > /etc/apt/sources.list
deb http://ftp.debian.org/debian bookworm main contrib
deb http://ftp.debian.org/debian bookworm-updates main contrib
# Proxmox VE pve-no-subscription repository provided by proxmox.com,
# NOT recommended for production use
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
# security updates
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
echo -e "\e[32mPopulated new sources.list\e[0m"

# Update and upgrade packages
apt-get update
echo "Updated available package updates"
apt-get upgrade -y
echo -e "\e[32mUpgraded packages\e[0m"

# Update Proxmox LXC images
pveam update
echo -e "\e[32mUpdated Proxmox LXC images\e[0m"

# Backup current network interfaces file
cp /etc/network/interfaces /etc/network/interfaces.bak

# Update network configuration
sed -i '/^source \/etc\/network\/interfaces.d\/\*/i\
auto vmbr1\n\
iface vmbr1 inet static\n\
    address 10.0.0.1/24\n\
    bridge-ports none\n\
    bridge-stp off\n\
    bridge-fd 0\n\
\n\
    # NAT SETTINGS\n\
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward\n\
    post-up iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o vmbr0 -j MASQUERADE\n\
    post-down iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o vmbr0 -j MASQUERADE\n\
    post-up   iptables -t raw -I PREROUTING -i fwbr+ -j CT --zone 1\n\
    post-down iptables -t raw -D PREROUTING -i fwbr+ -j CT --zone 1' /etc/network/interfaces

echo -e "\e[32mUpdated /etc/network/interfaces\e[0m"

# Bring up the new network interface
ifup vmbr1
echo -e "\e[32mStarted vmbr1\e[0m"

# Prompt to reboot the system
echo -e "\e[32mFeel free to set up firewall rules. It should now be compatible with the NAT bridge (vmbr1) created.\e[0m"
echo "Press any key to reboot the system..."
read -n 1 -s
echo -e "\e[32mRebooting\e[0m"
reboot
