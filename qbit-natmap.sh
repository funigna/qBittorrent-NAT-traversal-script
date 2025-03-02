#!/bin/sh
public_addr=$1
public_port=$2
private_port=$4
private_addr=$6
protocol=$5
fw_rule_name='allow-qbittorrent-ipv6'
ipv6_addr="::1:0:1:1"
qb_addr_url="http://192.168.1.1:8080" 
qb_ip_addr="192.168.1.1"
qb_username="admin"
qb_password="adminadmin"

if [ -z "$private_port" ] || [ -z "$public_port" ] || [ -z "$protocol" ]; then
    echo "Invalid argument"
    exit 1
fi
echo "STUN OK, public $public_addr:$public_port, private $private_addr:$private_port"

# based on https://github.com/Mythologyli/qBittorrent-NAT-TCP-Hole-Punching
qb_cookie=$(curl -s -i --header "Referer: $qb_addr_url" --data "username=$qb_username&password=$qb_password" "$qb_addr_url/api/v2/auth/login" | grep -i "set-cookie" | awk '{print $2}' | tr -d '\r\n')
qb_changeport=$(curl -s -X POST -b "$qb_cookie" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode 'json={"listen_port":'"$public_port"'}' "$qb_addr_url/api/v2/app/setPreferences")
echo "qBittorrent listen port updated to $public_port..."

if nft list tables | grep -q "qbit_redirect"; then
    nft flush table inet qbit_redirect
else
    nft add table inet qbit_redirect
fi
nft 'add chain inet qbit_redirect prerouting { type nat hook prerouting priority -100; }'

if [ "$protocol" = "tcp" ]; then
    if [ -z "$qb_ip_addr" ]; then
        nft add rule inet qbit_redirect prerouting tcp dport "$private_port" redirect to :"$public_port"
    else
        nft add rule inet qbit_redirect prerouting tcp dport "$private_port" dnat ip to "$qb_ip_addr:$public_port"
    fi
fi

if [ "$protocol" = "udp" ]; then
    if [ -z "$qb_ip_addr" ]; then
        nft add rule inet qbit_redirect prerouting udp dport "$private_port" redirect to :"$public_port"
    else
        nft add rule inet qbit_redirect prerouting udp dport "$private_port" dnat ip to "$qb_ip_addr:$public_port"
    fi
fi

i=0
while true; do
  rule_name=$(uci get "firewall.@rule[$i].name" 2> /dev/null)
  if [ $? != 0 ]; then
    rule_name=$(uci add firewall rule)
    uci set firewall."$rule_name".name="$fw_rule_name"
    uci set firewall."$rule_name".src='wan'  #change here if you have another zone name
    uci set firewall."$rule_name".dest='lan'
    uci set firewall."$rule_name".family='ipv6'
    uci set firewall."$rule_name".target='ACCEPT'
    uci set firewall."$rule_name".dest_port="$public_port"
    uci set firewall."$rule_name".proto='tcp udp'
    uci set firewall."$rule_name".dest_ip="$ipv6_addr/::ffff:ffff:ffff:ffff"
    uci commit firewall
    service firewall restart
    break
  fi

  if [ "$rule_name" = "$fw_rule_name" ]; then
    uci set firewall.@rule[$i].dest_port="$public_port"
    uci set firewall.@rule[$i].dest_ip="$ipv6_addr/::ffff:ffff:ffff:ffff"
    uci commit firewall
    service firewall restart
    break
  fi
  i=$((i+1))
done
echo "Firewall updated"