This script is to be used on fresh proxmox installs. It's mainly for my personal-use so please dont expect this to work flawlessly in every aspect at any time.
This script basically just gets everything updated and creates a NAT bridge at 10.0.0.1/24 as well as the appropriate iptables rules for it (compatible with proxmox datacenter/node-level firewall)

- Removes original apt sources
- Adds new apt sources (debian repos, proxmox VE no-subscription repo)
- Updates and upgrades packages
- Updates LXC images in proxmox
- backs up original network (/etc/network/interfaces) config
- adds network config to create a NAT bridge at 10.0.0.1/24 named vmbr1
- adds necessary NAT/iptables rules for the NAT bridge to work (even with proxmox firewall enabled)
- brings online vmbr1
- downloads debian 12 iso file for KVMs for quick/immediate use
- downloads debian 12 image for LXC containers for quick/immediate use
- reboots

```
wget https://raw.githubusercontent.com/xiaoyong-wang/proxmox-init/main/init.sh && chmod +x init.sh && ./init.sh
```
