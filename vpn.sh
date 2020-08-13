#!/bin/bash
# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
ANU=$(ip -o $ANU -4 route show to default | awk '{print $5}');

# Install OpenVPN dan Easy-RSA
apt install openvpn easy-rsa -y
apt install openssl iptables -y 

cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir /etc/openvpn/easy-rsa/keys
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="ID"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="ID"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="ID"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_ORG="PandaEver"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="justpandaevers@gmail.com"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyOrganizationalUnit"|export KEY_OU="PandaEver"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="PandaEver"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU=changeme|export KEY_OU=PandaEver|' /etc/openvpn/easy-rsa/vars

# Create Diffie-Helman Pem
openssl dhparam -out /etc/openvpn/dh2048.pem 2048

# Create PKI
cd /etc/openvpn/easy-rsa
cp openssl-1.0.0.cnf openssl.cnf
. ./vars
./clean-all
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*

# Create key server
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server

# Setting KEY CN
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" client

# cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn
cd
cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn/server.crt
cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn/server.key
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt
chmod +x /etc/openvpn/ca.crt
cd /root
mkdir /root/openconf
# Buat config server TCP 1194
cd /etc/openvpn

cat > /root/openconf/server-tcp-1194.conf <<-END
port 1194
proto tcp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/server.crt
key easy-rsa/keys/server.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 10.6.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-tcp-1194.log
verb 3
END

# Buat config server UDP 2200
cat > /root/openconf/server-udp-2200.conf <<-END
port 2200
proto udp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/server.crt
key easy-rsa/keys/server.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 10.7.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-udp-2200.log
verb 3
END

cd

# nano /etc/default/openvpn
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
# Cari pada baris #AUTOSTART=”all” hilangkan tanda pagar # didepannya sehingga menjadi AUTOSTART=”all”. Save dan keluar dari editor

# restart openvpn dan cek status openvpn
/etc/init.d/openvpn restart
/etc/init.d/openvpn status

# aktifkan ip4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
# edit file sysctl.conf
# nano /etc/sysctl.conf
# Uncomment hilangkan tanda pagar pada #net.ipv4.ip_forward=1

# Konfigurasi dan Setting untuk Client
mkdir clientconfig
cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} clientconfig/
cd clientconfig

# Buat config client TCP 1194
cat > /root/openconf/client-tcp-1194.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 1194
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /root/openconf/client-tcp-1194.ovpn;

# Buat config client UDP 2200
cat > /root/openconf/client-udp-2200.ovpn <<-END
client
dev tun
proto udp
remote xxxxxxxxx 2200
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /root/openconf/client-udp-2200.ovpn;

# Buat config client SSL
cat > /root/openconf/client-tcp-ssl.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 442
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /root/openconf/client-tcp-ssl.ovpn;

cd
# pada tulisan xxx ganti dengan alamat ip address VPS anda 
/etc/init.d/openvpn restart

# masukkan certificatenya ke dalam config client TCP 1194
echo '<ca>' >> /root/openconf/client-tcp-1194.ovpn
cat /etc/openvpn/ca.crt >> /root/openconf/client-tcp-1194.ovpn
echo '</ca>' >> /root/openconf/client-tcp-1194.ovpn


# masukkan certificatenya ke dalam config client UDP 2200
echo '<ca>' >> /root/openconf/client-udp-2200.ovpn
cat /etc/openvpn/ca.crt >> /root/openconf/client-udp-2200.ovpn
echo '</ca>' >> /root/openconf/client-udp-2200.ovpn

# masukkan certificatenya ke dalam config client SSL
echo '<ca>' >> /root/openconf/client-tcp-ssl.ovpn
cat /etc/openvpn/ca.crt >> /root/openconf/client-tcp-ssl.ovpn
echo '</ca>' >> /root/openconf/client-tcp-ssl.ovpn
apt install zip -y
zip -r /home/vps/public_html/ovpn.zip /root/openconf/*

#firewall untuk memperbolehkan akses UDP dan akses jalur TCP

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -I POSTROUTING -s 10.6.0.0/24 -o $ANU -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.7.0.0/24 -o $ANU -j MASQUERADE
iptables -A INPUT -i -m state --state NEW -p tcp --dport 1194 -j ACCEPT
iptables -A INPUT -i  -m state --state NEW -p udp --dport 2200 -j ACCEPT

iptables-save > /etc/iptables.up.rules
chmod +x /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules

# Restart service openvpn
systemctl enable openvpn
systemctl start openvpn
/etc/init.d/openvpn restart

# set iptables tambahan
iptables -F -t nat
iptables -X -t nat
iptables -A POSTROUTING -t nat -j MASQUERADE
iptables-save > /etc/iptables-opvpn.conf

# Restore iptables
cat > /etc/network/if-up.d/iptables <<-END
iptables-restore < /etc/iptables.up.rules
iptables -t nat -A POSTROUTING -s 10.6.0.0/24 -o $ANU -j SNAT --to xxxxxxxxx
iptables -t nat -A POSTROUTING -s 10.7.0.0/24 -o $ANU -j SNAT --to xxxxxxxxx
END
sed -i $MYIP2 /etc/network/if-up.d/iptables
chmod +x /etc/network/if-up.d/iptables


# restart opevpn
/etc/init.d/openvpn restart

# Delete script
history -c
rm -f /root/vpn.sh
