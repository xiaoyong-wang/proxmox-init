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

# Define the configuration to be inserted
vmbr1_config=$(cat <<EOF
auto vmbr1
iface vmbr1 inet static
    address 10.0.0.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0

    # NAT SETTINGS
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o vmbr0 -j MASQUERADE
    post-up   iptables -t raw -I PREROUTING -i fwbr+ -j CT --zone 1
    post-down iptables -t raw -D PREROUTING -i fwbr+ -j CT --zone 1
    
EOF
)

# Insert the configuration before the source line
awk -v new_config="$vmbr1_config" '
/^source \/etc\/network\/interfaces.d\/\*/ {
    print new_config
}
{ print }
' /etc/network/interfaces > /etc/network/interfaces.new

# Replace the old file with the new file
mv /etc/network/interfaces.new /etc/network/interfaces

echo -e "\e[32mUpdated /etc/network/interfaces\e[0m"

# Apply the new network configuration
ifup vmbr1
echo -e "\e[32mStarted vmbr1\e[0m"

# download debian iso
apt-get install wget -y
sudo wget -O /var/lib/vz/template/iso/debian-12.7.0-amd64-netinst.iso https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.7.0-amd64-netinst.iso
echo -e "\e[32mDownloaded Debian 12 ISO for KVMs\e[0m"

# download debian lxc image
pveam download local debian-12-standard_12.7-1_amd64.tar.zst
echo -e "\e[32mDownloaded Debian 12 image for LXC containers\e[0m"

# Prompt to reboot the system
echo -e "\e[32mFeel free to set up firewall rules. It should now be compatible with the NAT bridge (vmbr1) created.\e[0m"
echo "Press any key to reboot the system..."
read -n 1 -s
echo -e "\e[32mRebooting\e[0m"
reboot
