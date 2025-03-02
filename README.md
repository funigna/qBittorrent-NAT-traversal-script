# qBittorrent-NAT-traversal-script
work with luci-app-natmap, openwrt, immortalwrt

this script changes qBittorrent listen port through webUI, configure firewall to redirect traffic according to natmap's return.

requires nat1(fullcone) network.

download the sh file to your router(e.g. /root/natmap_qbit.sh).

configure natmap to use the script by changing path in luci.

bind port set to 0 to let natmap choose automatically.

set protocal to ipv4 only.

set keep-alive, stun server(e.g. stun.hot-chilli.net), http server(whatever), disable forward.

edit sh to your own setup

```
fw_rule_name='allow-qbittorrent-ipv6'
ipv6_addr="::1:0:1:1"
qb_addr_url="http://192.168.1.1:8080" 
qb_ip_addr="192.168.1.1"
qb_username="admin"
qb_password="adminadmin"
```

test it with tcp.ping.pe and tcp6.ping.pe, to see if it is working.

dont forget to add /root into openwrt's save list, otherwise script will not survive after reboot.
