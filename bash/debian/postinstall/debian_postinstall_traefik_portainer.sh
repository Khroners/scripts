#!/bin/bash

# Automatic debian configuration for traefik/portainer by Khroners 
current_path=$(pwd)
function System-Verification {
  if [[ $(arch) != *"64" ]]
    then
    tput setaf 5; echo "ERROR : Please install a x64 version of your OS !"
    exit
  fi
  if [ $(whoami) != "root" ]
    then
    tput setaf 5; echo "ERROR : Plese execute this script as Root !"
    exit
  fi
}

# Changing APT sources
version=$(grep "VERSION=" /etc/os-release |awk -F= {' print $2'}|sed s/\"//g |sed s/[0-9]//g | sed s/\)$//g |sed s/\(//g)
function Change-Source {
  echo "deb http://debian.mirrors.ovh.net/debian/ $version main contrib non-free
  deb-src http://debian.mirrors.ovh.net/debian/ $version main contrib non-free
  
  deb http://security.debian.org/ $version/updates main contrib non-free
  deb-src http://security.debian.org/ $version/updates main contrib non-free
  
  # $version-updates, previously known as 'volatile'
  deb http://debian.mirrors.ovh.net/debian/ $version-updates main contrib non-free
  deb-src http://debian.mirrors.ovh.net/debian/ $version-updates main contrib non-free" > /etc/apt/sources.list
}


# Updating packages
function Install-Essentials-Packages {
  apt update && apt upgrade -y
  apt install -y sudo 
  apt install -y openssh-server
  apt install -y locate
  apt install -y curl
  apt install -y fail2ban
  apt install -y apt-transport-https
  apt install -y git
}

# Dependancies & Docker
function Install-Docker {
  tput setaf 2; apt-get install -y ca-certificates gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}


function Update-db {
  updatedb
}
#Portainer & Traefik installation
function Install-TraefikPortainer {
  traefik_compose_path="/apps/traefik/docker-compose.yml"
  traefik_static_config_path="/apps/traefik/traefik.yml"
  traefik_dynamic_config_path="/apps/traefik/config/tls.yml"

  mkdir /apps/
  git clone https://github.com/Khroners/Traefik-with-A-plus-on-SSL-Labs-Headers
  mv Traefik-with-A-plus-on-SSL-Labs-Headers/ /apps/traefik
  rm /apps/traefik/acme.json
  touch /apps/traefik/acme.json
  chmod 600 /apps/traefik/acme.json
  sed "s/exemple.com/"$ndd"/" /apps/traefik/docker-compose.yml
  if [ $cert = "n" ]
    then
    sed -i '21s/^.//' $traefik_compose_path
    sed -i '36s/^.//' $traefik_compose_path
    sed -i '60s/^.//' $traefik_compose_path
    sed -i '23s/^/#/' $traefik_compose_path
    sed -i '16,22s/^.//' $traefik_static_config_path
    sed -i '23,32s/^/#/' $traefik_dynamic_config_path
  fi
  sed -i "s/exemple.com/$ndd/" $traefik_compose_path
  tput setaf 2; docker network create proxy
  cd /apps/traefik
  docker-compose up -d
}

# Changing the SSH Port
function Change-SSHPort {
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config_backup

  for file in /etc/ssh/sshd_config
  do
    echo "Treatement $file ..."
    sed -i -e "s/#Port 22/Port $ssh_port/" "$file"
  done  
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput setaf 7; echo "                                 => SSH Port replaced by $ssh_port.                                "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"

}

# Changing the MOTD
function Change-MOTD {
  server_ip=$(hostname -i)
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
  tput bold; tput setaf 7; echo "                      => Server IP Address is $server_ip.                     "
  tput setaf 7; echo "----------------------------------------------------------------------------------------------------"


  echo "
  ██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗
  ██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝
  ██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗
  ██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝
  ╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗
   ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝
               Server   : $name_server
               IP       : $server_ip
               Provider : $name_provider
  " > /etc/motd
  
}
#-----------------------------------------------------------------------------------------------------------------------------------
install_traefik = "n"
clear
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 7; echo "                  Fresh install of Debian & Traefik/Portainer installation script                                 "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"


tput setaf 6; read -p "Do you want to change the SSH port ? (recommanded) (y/n)  " change_sshport
if [ $change_sshport = "y" ]
  then
    tput setaf 6; read -p "===>     Please enter the new SSH port  (ex : 2020) : " ssh_port
fi
echo ""

tput setaf 6; read -p "Do you want to change the MOTD ? (y/n)  " change_motd
if [ $change_motd = "y" ]
  then
  tput setaf 6; read -p "===>     Enter the name of the server : " name_server
  tput setaf 6; read -p "===>     Enter the name of your provider : " name_provider
fi
echo ""

tput setaf 6; read -p "Do you want to install Docker ? (y/n)  " install_docker
if [ $install_docker = "y" ]
  then
  echo ""
  tput setaf 6; read -p "Do you want to install Traefik and Portainer ? (y/n)  " install_traefik
  if [ $install_traefik = "y" ]
    then
    tput setaf 6; read -p "===>     Enter the name of your domain (ex : exemple.fr) : " ndd
    tput setaf 6; read -p "===>     Do you already have a wildcard certificate ? (y/n) : " cert
    if [ $cert = "n" ]
      then
      tput setaf 6; read -p "===>     Enter your mail address for Let's Encrypt : " email
    fi
    echo ""
    while [ -z $redirection ] || [ $redirection != 'y' ]
    do
      tput setaf 3; echo "WARNING : please make the following redirections :"
      tput setaf 3; echo "=> Traefik : traefik.$ndd => Public IP of your server ! (DNS Type A : traefik.$ndd --> your server IP address"
      tput setaf 3; echo "=> Portainer : portainer.$ndd => Public IP of your server ! (DNS Type A : portainer.$ndd --> your server IP address"
      echo ""
      tput setaf 3; read -p "Have the redirects been configured correctly? (y/n) " redirection
    done
  fi
fi
echo ""


tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 7; echo "                                           Begin of the script                                          "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
echo ""
echo ""


tput setaf 6; echo "System verification................................................................... In progress"
Verif-System
tput setaf 7; echo "System verification................................................................... OK"
echo ""


tput setaf 6; echo "Sources configuration................................................................. In progress"
Change-Source
tput setaf 7; echo "Sources configuration................................................................. OK"
echo ""

tput setaf 6; echo "Essentials packages installation........................................................ In progress"
Install-PaquetsEssentiels
tput setaf 7; echo "Essentials packages installation........................................................ OK"
echo ""


tput setaf 6; echo "Updating database.......................................................... In progress"
Update-db
tput setaf 7; echo "Updating database.......................................................... OK"

echo ""
echo ""
if [ $install_docker = "y" ]
  then
  tput setaf 6; echo "Docker installation..................................................................... In progress"
  Install-Docker
  tput setaf 7; echo "Docker installation..................................................................... OK"
fi

echo ""
echo ""
if [ $install_traefik = "y" ]
  then
  tput setaf 6; echo "Installation of Traefik and Portainer.................................................... In progress"
  Install-TraefikPortainer
  tput setaf 7; echo "Installation of Traefik and Portainer.................................................... OK"
fi

echo ""
echo ""
if [ $change_sshport = "y" ]
  then
  tput setaf 6; echo "Change of SSH port.................................................................... In progress"
  Change-SSHPort
  tput setaf 7; echo "Change of port.................................................................... OK"
fi

echo ""
echo ""
if [ $change_motd = "y" ] 
  then
  tput setaf 6; echo "Change of MOTD....................................................................... In progress"
  Change-MOTD
  tput setaf 7; echo "Change of MOTD....................................................................... OK"
fi

echo ""
echo ""
if [ $install_traefik = "y" ]
  then
  echo ""
  echo ""
  tput bold; tput setaf 7; echo "LIST OF RUNNING CONTAINERS : "
  tput setaf 3; echo ""
  docker container ls
fi

echo ""
echo ""
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput bold; tput setaf 7; echo "                               => Preparation completed <=                                "
tput setaf 7; echo ""
version_docker=docker
if [ $install_docker = "y" ]
  then
  tput bold; tput setaf 7; echo "                               Portainer.$ndd                                            "
  tput bold; tput setaf 7; echo "                               Traefik.$ndd                                            "
  tput bold; tput setaf 7; echo "                          Traefik login : admin / admin                          "
  tput setaf 7; echo ""
fi
tput setaf 7; echo ""
if [ $install_traefik = "y" ]
  then
  docker_version=$(docker -v)
  docker_compose_version=$(docker-compose -v)
  tput bold; tput setaf 7; echo "                               $docker_version                                            "
  tput bold; tput setaf 7; echo "                               $docker_compose_version                                           "
  tput setaf 7; echo ""
fi
tput bold; tput setaf 7; echo "                                Please reconnect                                "
if [ $change_sshport = "y" ]
  then
  tput bold; tput setaf 7; echo "                             Your new SSH port : $ssh_port                        "
fi
tput setaf 7; echo ""
tput bold; tput setaf 6; echo "                                       By Khroners                                       "
tput bold; tput setaf 6; echo "                               Docs.khroners.fr / github.com/Khroners                               "
tput setaf 7; echo "----------------------------------------------------------------------------------------------------"
tput setaf 2; echo ""

cd $current_path
sleep 3
# Reboot of SSH service
service ssh restart
