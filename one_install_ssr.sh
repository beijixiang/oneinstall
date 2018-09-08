#!/bin/bash

#装机一键脚本
install_ssr(){

	read -p '请输入节点的NODE_ID:' node_id
	echo '准备开始安装ssr'
	echo '更新软件库'
	yum update -y
	yum install git wget gcc -y
	echo '安装libsodiu'
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-1.0.10.tar.gz
	tar xf libsodium-1.0.10.tar.gz && cd libsodium-1.0.10
	./configure && make -j2 && make install
	ldconfig
	
	echo '安装ssr'
	wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py
	python get-pip.py
	
	pip install cymysql
	cd ..
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git
	cd shadowsocks
	chmod +x *.sh
	# 配置程序
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
	sed -i "s/NODE_ID = 1/NODE_ID = $node_id/" userapiconfig.py
	sed -i "s/WEBAPI_URL = 'https:\/\/zhaoj.in'/WEBAPI_URL = 'http:\/\/198.13.53.189'/" userapiconfig.py
	sed -i "s/WEBAPI_TOKEN = 'glzjin'/WEBAPI_TOKEN = '123456'/" userapiconfig.py
	sed -i "s/MYSQL_HOST = '127.0.0.1'/MYSQL_HOST = '198.13.53.189'/" userapiconfig.py
	sed -i "s/MYSQL_PASS = 'ss'/MYSQL_PASS = 'shang19950328'/" userapiconfig.py
	sed -i "s/MYSQL_DB = 'shadowsocks'/MYSQL_DB = 'ss'/"	userapiconfig.py


	#升级后端
	yum -y install python-devel
	yum -y install libffi-devel
	yum -y install openssl-devel
	
	pip install -r requirements.txt
	
	curl http://198.13.53.189/mod_mu/func/ping?key=123456 >> ~/oneinstall.log
	
	#关闭防火墙
	systemctl stop firewalld.service
	systemctl disable firewalld.service

	echo '安装完成，请检查是否安装成功'


}

open_bbr(){

	echo '正在开启bbr'
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	sysctl -p 

	sysctl net.ipv4.tcp_available_congestion_control
	sysctl net.ipv4.tcp_congestion_control
	lsmod | grep tcp_bbr

	echo 'bbr已开启，请检查输出信息'
}

change_ke(){

	echo '准备更换内核'
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org	
	rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
	yum install yum-plugin-fastestmirror -y
	yum --enablerepo=elrepo-kernel install kernel-ml -y
	grub2-set-default 0
	reboot
}
cd ~
echo '请选择你要安装的功能'
echo '1  安装 ssr服务器'
echo '2  开启bbr'
echo '3  更换4.4内核'
read -p '请输入你的选择:' select

echo '你输入了   ' $select

if [ $select == 1 ]
then 
	install_ssr
elif [ $select == 2 ]
then 
	open_bbr
elif [ $select == 3 ]
then  
	change_ke
else
	echo '选项输入有误，请重新执行该脚本，并选择正确的参数'
fi


