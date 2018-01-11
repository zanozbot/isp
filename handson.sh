@hq
    - Adapter 1 Attached to: Bridged Network
    - Adapter 2 Attached to: Internal Network (e.g. hq_subnet)
@br
    - Adapter 1 Attached to: Bridged Network
    - Adapter 2 Attached to: Internal Network (e.g. br_subnet)

Both machines
    - https://ucilnica.fri.uni-lj.si/mod/page/view.php?id=8650 up to Download the script template

@hq
    - add to /etc/network/interfaces
auto enp0s8
iface enp0s8 inet static
    address 10.1.0.1
    netmask 255.255.0.0
    
    - sudo service network-manager restart
    - sudo ifup enp0s8
    - ifconfig to check
    - enable packet forwarding echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

@br
    - add to /etc/network/interfaces
auto enp0s8
iface enp0s8 inet static
    address 10.2.0.1
    netmask 255.255.0.0
    
    - sudo service network-manager restart
    - sudo ifup enp0s8
    - ifconfig to check
    - echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward (enables packet forwarding)

@hq
    - open /etc/ipsec.conf
conn %default
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1
        keyexchange=ikev2
        authby=secret

conn net-net
        leftsubnet=10.1.0.0/16
        leftfirewall=yes
        leftid=@hq
!CHANGE!        right=192.168.0.43
        rightsubnet=10.2.0.0/16
        rightid=@br
        auto=add

    - open /etc/ipsec.secrets
@hq @br : PSK "this_is_my_psk"

    - sudo ipsec restart

@br
    - open /etc/ipsec.conf
conn %default
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1
        keyexchange=ikev2
        authby=secret

conn net-net
        leftsubnet=10.2.0.0/16
        leftfirewall=yes
        leftid=@br
!CHANGE!        right=192.168.0.42
        rightsubnet=10.1.0.0/16
        rightid=@hq
        auto=add

    - open /etc/ipsec.secrets
@hq @br : PSK "this_is_my_psk"

    - sudo ipsec restart

@hq 
    - sudo ipsec up net-net

@hq/@br
    - sudo apt update
    - sudo apt install openssh-server openssh-client apache2 curl

@hq
    - choose empty passphrase
sudo ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
sudo ssh-keygen -t rsa   -f /etc/ssh/ssh_host_rsa_key
sudo ssh-keygen -t dsa   -f /etc/ssh/ssh_host_dsa_key
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key

@br
    - choose empty passphrase
ssh-keygen -t rsa
ssh-keygen -t dsa
ssh-keygen -t ecdsa

    - ssh 10.1.0.1 (type yes)
    - ssh-copy-id isp@10.1.0.1
    - ssh isp@10.1.0.1 (should not ask for password)

@hq
    - open file /etc/ssh/sshd_config
PasswordAuthentication no
    - sudo service ssh restart

    - open handson-tables.sh
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ICMP
iptables -A INPUT -p icmp -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p icmp -m state --state NEW -j ACCEPT

# SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# ISAKMP
iptables -A INPUT -p udp -m multiport --ports 500,4500 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp -m multiport --ports 500,4500 -m state --state NEW -j ACCEPT


# IPsec
iptables -A INPUT -p ah -m state --state NEW -j ACCEPT
iptables -A INPUT -p esp -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p ah -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p esp -m state --state NEW -j ACCEPT
    - chmod +x handson-tables.sh
    - sudo ./handson-tables.sh restart
