#!/bin/bash

#装机一键脚本
install_ssr_panel(){

	echo "正在准备安装ssr_panel"
	
	#一键安装lnmp
	#正在准备安装lnmp
	cd ~
	yum install screen -y
	screen -S lnmp
	wget http://soft.vpser.net/lnmp/lnmp1.5.tar.gz -cO lnmp1.5.tar.gz && tar zxf lnmp1.5.tar.gz && cd lnmp1.5 && ./install.sh lnmp

	echo "设置虚拟主机。。。。。。"
	lnmp vhost add
	
	read -p "输入你的虚拟主机地址" vh
	cp /usr/local/nginx/conf/vhost/$vh.conf /usr/local/nginx/conf/vhost/$vh.conf.bak
	cp ~/oneinstall/example.conf /usr/local/nginx/conf/vhost/$vh.conf
	sed -i "s/server_name hostname;/server_name $vh;/" /usr/local/nginx/conf/vhost/$vh.conf
	sed -i "s/root  \/home\/wwwroot\/defaul;/root  \/home\/wwwroot\/$vh/public;" /usr/local/nginx/conf/vhost/$vh.conf
	
	#下载ss_panel
	echo "正在下载ss_panel"
	cd /home/wwwroot/你的域名
	git clone -b new_master https://github.com/glzjin/ss-panel-v3-mod.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	chown -R root:root *
	chmod -R 755 *
	chown -R www:www storage
	chattr -i .user.ini
	mv .user.ini public
	cd public
	chattr +i .user.ini
	service nginx restart
	
	#修改防跨目录的设置, 否则肯定报错
	echo "输入: /home/wwwroot/$vh/public"
	cd ~/lnmp1.5/tools/
	./remove_open_basedir_restriction.sh

	#提示手动配置数据库
	echo "浏览器打开 http://$vh/phpmyadmin"
	echo "用户 : root\n
	密码 :安装 lnmp 时设置的\n
	需要创建一个数据库和一个访问这个数据库的用户\n
	点击 用户 -> 新建 -> 添加用户\n
	登录信息 :\n
	Username 选择 使用文本域 , 填写你的用户名 如 sspanel\n
	Host 选择任意主机 %\n
	密码 选择使用文本域 填写密码\n
	用户数据库 :\n
	勾选 创建与用户同名的数据库并授予所有权限\n
	全局权限 :\n
	全选\n
	接着按执行 选择刚刚新建的数据库 sspanel 导入程序目录下的 glzjin_all.sql\n"

	read -p "请按上面操作导入数据库" t1
	read -p "这是防止误触" t2
	read -P "还是防止误触" t3

	#配置 sspanel
	echo "正在配置sspanel"
	cd /home/wwwroot/$vh
	php composer.phar install
	cp ~/oneinstall/.config.php config/.config.php
	read -p "输入数据库密码:" mypasswd
	sed -i "s/hostname/http:\/\/$vh" config/.config.php
	sed -i "s/mypasswd/$mypasswd/" config/.config.php
	
	#创建网站管理员
	cd /home/wwwroot/$vh/public
	php xcat createAdmin
	php xcat syncusers
	

	#设置天朝时间
	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	#提示手动输入
	echo "对服务器进行计划任务的设置,执行 crontab -e 命令, 添加以下五段"
	echo "30 22 * * * php /home/wwwroot/$vh/xcat sendDiaryMail"
	echo "*/1 * * * * php /home/wwwroot/$vh/xcat synclogin"
	echo "*/1 * * * * php /home/wwwroot/$vh/xcat syncvpn"
	echo "0 0 * * * php /home/wwwroot/$vh/xcat dailyjob"
	echo "*/1 * * * * php /home/wwwroot/$vh/xcat checkjob"
	echo "*/1 * * * * php /home/wwwroot/$vh/xcat syncnas"

	echo "执行/etc/init.d/cron restart"

	

}

install_ssr(){

	cd ~
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
echo '4  安装ssr_panel'
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
elif [ $select == 4 ]
then
	install_ssr_panel

else
	echo '选项输入有误，请重新执行该脚本，并选择正确的参数'
fi


