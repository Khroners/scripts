#!/usr/bin/env bash
set -euo pipefail

clear
tput setaf 7; read -p "Entrez le nom du serveur : " server_name
tput setaf 7; read -p "Entrez l'ip du serveur Zabbix : " server_ip
tput setaf 7; read -p "Entrez HostMetadata: " hostmetadata
wget https://repo.zabbix.com/zabbix/5.2/debian/pool/main/z/zabbix-release/zabbix-release_5.2-1+debian10_all.deb
dpkg -i zabbix-release_5.2-1+debian10_all.deb

apt update
apt install zabbix-agent -y

for file in /etc/zabbix/zabbix_agentd.conf
do
  echo "Traitement de $file ..."
  sed -i -e "s/Server=127.0.0.1/Server=$server_ip/g" "$file"
  sed -i -e "s/ServerActive=127.0.0.1/ServerActive=$server_ip/g" "$file"
  sed -i -e "s/Hostname=Zabbix server/Hostname=$server_name/g" "$file"
  sed -i -e "s/ #HostMetadata=/HostMetadata=$hostmetadata/g" "$file"
done

service zabbix-agent start
systemctl enable zabbix-agent
systemctl start zabbix-agent

clear
tput bold; tput setaf 7; echo "STATUS DU SERVICE AGENT-ZABBIX : "
tput setaf 3; echo ""
systemctl status zabbix-agent
tput setaf 3; echo ""
