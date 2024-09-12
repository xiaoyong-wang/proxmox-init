#!/bin/bash
rm /etc/apt/sources.list.d/*
echo -e "\e[32mRemoved sources.list.d dir contents\e[0m"
rm /etc/apt/sources.list
echo -e "\e[32mRemoved sources.list\e[0m"
touch /etc/apt/sources.list
echo -e "\e[32mCreated new sources.list\e[0m"
echo "deb http://ftp.debian.org/debian bookworm main contrib" >> /etc/apt/sources.list
echo "deb http://ftp.debian.org/debian bookworm-updates main contrib" >> /etc/apt/sources.list
echo "# Proxmox VE pve-no-subscription repository provided by proxmox.com," >> /etc/apt/sources.list
echo "# NOT recommended for production use" >> /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list
echo "# security updates" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bookworm-security main contrib" >> /etc/apt/sources.list
echo -e "\e[32mPopulated new sources.list\e[0m"
apt-get update
echo "Updated available package updates"
apt-get upgrade -y
echo -e "\e[32mUpgraded packages\e[0m"
pveam update
echo -e "\e[32mUpdated Proxmox LXC images\e[0m"
cat <<EOF > /etc/network/interfaces.d/vmbr1.cfg
auto vmbr1
iface vmbr1 inet static
    address 10.0.0.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0

    # NAT SETTINGS
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up iptables -t nat -A POSTROUTING -s '10.0.0.0/24' -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '10.0.0.0/24' -o vmbr0 -j MASQUERADE
    post-up   iptables -t raw -I PREROUTING -i fwbr+ -j CT --zone 1
    post-down iptables -t raw -D PREROUTING -i fwbr+ -j CT --zone 1
EOF
echo -e "\e[32mCreated vmbr1\e[0m"
ifup vmbr1
echo -e "\e[32mStarted vmbr1\e[0m"
echo -e "\e[32mFeel free to setup firewall rules. It should now be compatible with the NAT bridge (vmbr1) created.\e[0m"
# prompt to reboot the server after making all these changes
echo "Press any key to reboot the system..."
read -n 1 -s
echo -e "\e[32mRebooting\e[0m"
reboot
