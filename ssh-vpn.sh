#!/bin/bash
# initializing var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
ANU=$(ip -o $ANU -4 route show to default | awk '{print $5}');

#detail nama perusahaan
country=ID
state=Indonesia
locality=Indonesia
organization=PandaEver
organizationalunit=PandaEver
commonname=PandaEver
email=JustPandaEvers@gmail.com

# simple password minimal
wget -O /etc/pam.d/common-password "https://raw.githubusercontent.com/JustPandaEver/ssh/master/common-password-deb9"
chmod +x /etc/pam.d/common-password

# go to root
cd

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#update
apt-get update -y

# install wget and curl
apt-get -y install wget curl

# remove unnecessary files
apt -y autoremove
apt -y autoclean
apt -y clean
apt-get -y remove --purge unscd

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# install webserver
apt-get -y install nginx

# install neofetch
apt-get update -y
apt-get -y install gcc
apt-get -y install make
apt-get -y install cmake
apt-get -y install git
apt-get -y install screen
apt-get -y install unzip
apt-get -y install curl
git clone https://github.com/dylanaraps/neofetch
cd neofetch
make install
make PREFIX=/usr/local install
make PREFIX=/boot/home/config/non-packaged install
make -i install
apt-get -y install neofetch
cd
echo "clear" >> .profile
echo "neofetch" >> .profile

# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/JustPandaEver/ssh/master/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Setup by PandaEver</pre>" > /home/vps/public_html/index.html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/JustPandaEver/ssh/master/vps.conf"
/etc/init.d/nginx restart

# install badvpn
cd
apt-get install cmake make gcc -y
cd
wget https://raw.githubusercontent.com/janda09/private/master/badvpn-1.999.128.tar.bz2
tar xf badvpn-1.999.128.tar.bz2
mkdir badvpn-build
cd badvpn-build
cmake ~/badvpn-1.999.128 -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
echo 'badvpn-udpgw --listen-addr 127.0.0.1:Badvpn_Port1 > /dev/nul &' >> /etc/rc.local
badvpn-udpgw --listen-addr 127.0.0.1:Badvpn_Port1 > /dev/nul &
echo 'badvpn-udpgw --listen-addr 127.0.0.1:Badvpn_Port2 > /dev/nul &' >> /etc/rc.local
badvpn-udpgw --listen-addr 127.0.0.1:Badvpn_Port2 > /dev/nul &
# setting port ssh
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
echo "DROPBEAR_PORT=80" >> /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 110 -p 109 -p 456"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/dropbear restart

# install squid
cd
apt-get -y install squid3
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/JustPandaEver/ssh/master/squid3.conf"
sudo sed -i $MYIP2 /etc/squid/squid.conf

# setting vnstat
apt-get -y install vnstat
vnstat -u -i $ANU
service vnstat restart 


# install stunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 443
connect = 127.0.0.1:109

[dropbear]
accept = 777
connect = 127.0.0.1:109

[dropbear]
accept = 222
connect = 127.0.0.1:109

[dropbear]
accept = 990
connect = 127.0.0.1:109

[openvpn]
accept = 442
connect = 127.0.0.1:1194

END

# make a certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

#OpenVPN
wget https://raw.githubusercontent.com/JustPandaEver/ssh/master/vpn.sh &&  chmod +x vpn.sh && bash vpn.sh

# install fail2ban
cdLEDinstall fail2ban
apt-get -y install fail2ban

# xml parser
cd
apt-get install -y libxml-parser-perl

# banner /etc/issue.net
wget -O /etc/issue.net "https://raw.githubusercontent.com/JustPandaEver/ssh/master/issue.net"
sed -i 's@#Banner none@Banner /etc/issue.net@g' /etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear

# download script
cd /usr/bin
wget -O menu "https://raw.githubusercontent.com/JustPandaEver/ssh/master/menu.sh"
wget -O usernew "https://raw.githubusercontent.com/JustPandaEver/ssh/master/usernew.sh"
wget -O trial "https://raw.githubusercontent.com/JustPandaEver/ssh/master/trial.sh"
wget -O hapus "https://raw.githubusercontent.com/JustPandaEver/ssh/master/hapus.sh"
wget -O member "https://raw.githubusercontent.com/JustPandaEver/ssh/master/member.sh"
wget -O delete "https://raw.githubusercontent.com/JustPandaEver/ssh/master/delete.sh"
wget -O cek "https://raw.githubusercontent.com/JustPandaEver/ssh/master/cek.sh"
wget -O speedtest "https://raw.githubusercontent.com/JustPandaEver/ssh/master/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/JustPandaEver/ssh/master/info.sh"
wget -O about "https://raw.githubusercontent.com/JustPandaEver/ssh/master/about.sh"
wget -O restart "https://raw.githubusercontent.com/JustPandaEver/ssh/master/restart.sh"
wget -O limit "https://raw.githubusercontent.com/JustPandaEver/ssh/master/user-limit.sh"

echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

chmod +x menu
chmod +x restart
chmod +x usernew
chmod +x trial
chmod +x hapus
chmod +x member
chmod +x delete
chmod +x cek
chmod +x speedtest
chmod +x info
chmod +x about
chmod +x limit

# finishing
cd
chown -R www-data:www-data /home/vps/public_html
/etc/init.d/nginx restart
/etc/init.d/openvpn restart
/etc/init.d/cron restart
/etc/init.d/ssh restart
/etc/init.d/dropbear restart
/etc/init.d/fail2ban restart
/etc/init.d/stunnel4 restart
/etc/init.d/squid start
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
estartf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

cd
rm -f /root/ssh-vpn.sh

# finihsing
clear
neofetch
netstat -ntlp
