#!/bin/bash

system=$(awk -F '=' 'NR==3{print $2}' /etc/os-release)
mysql_password='1qaz@WSX'
workdir=$(dirname "$0")
ip=$(ifconfig | grep -A1 eth | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:")

# 判断执行脚本是否为root用户，非root用户脚本退出
if [ `id -u` -ne 0 ]; then
    echo "----------请使用root用户执行脚本----------"
    exit
fi

# 判断操作系统,Ubuntu系统返回1，CentOS系统返回2
LNMP_system(){
    if [ ${system} == ubuntu ]; then
        return 1
    elif [ ${system} == '"centos"' ]; then
        return 2
    else
        echo "-----仅支持Ubuntu和CentOS7系统-----"
    fi
}

# Ubuntu初始化环境
LNMP_ubuntu_init(){
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
}

# CentOS初始化环境
LNMP_centos_init(){
    systemctl stop firewalld
    if [ "$?" -ne 0 ]; then
        echo "----------本脚本不支持CentOS6以下的版本（包括CentOS6系列）----------"
    fi
    systemctl disable firewalld
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
}

# CentOS安装所需源
LNMP_centos_rpm(){
    rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
}

# Ubuntu更新apt源
LNMP_ubuntu_apt(){
    apt-get -y update
}

# CentOS使用yum安装依赖包
LNMP_centos_yum(){
    yum -y install wget unzip 
    if [ -f '/etc/yum.repos.d/CentOS-Base.repo' ]; then
        cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak
    else
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    fi
    yum clean all
    yum makecache
    yum -y install epel-release yum-utils
    yum -y update
    rpm -ivh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    yum-config-manager --enable rhel-7-server-optional-rpms
    if [ "$?" -ne 0 ]; then
        echo "----------安装已经更新包失败，可能是网络或者本地不能使用yum的原因----------"
        exit
    fi
}

# Ubuntu清除旧的包
LNMP_ubuntu_remove(){
    apt-get -y remove nginx php-common php* 
}

# CentOS清除旧的包
LNMP_centos_remove(){
    yum -y remove nginx php-common php* mariadb*
}

# Ubuntu安装LNMP环境
LNMP_ubuntu_install(){
    apt-get -y install nginx
    apt-get -y install php7.0 php7.0-fpm php7.0-mysql php7.0-common php7.0-mbstring php7.0-gd php7.0-json php7.0-cli php7.0-curl libapache2-mod-php7.0
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$mysql_password''
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$mysql_password''
    apt-get -y install mysql-server
}

# CentOS安装LNMP环境
LNMP_centos_install(){
    yum -y install nginx
    yum -y install php70w php70w-gd php70w-mysql php70w-fpm php70w-mbstring
    yum -y install mysql-community-server
}

# Ubuntu修改nginx配置文件
LNMP_ubuntu_nginx(){
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_bak
    cp -rf ${workdir}/nginx.conf /etc/nginx/nginx.conf
    if [ "$?" -ne 0 ]; then
        echo "-----未找到nginx.conf文件-----"
        exit
    fi
}

# CentOS修改nginx配置文件
LNMP_centos_nginx(){
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_bak
    cp -rf ${workdir}/nginx.conf /etc/nginx/nginx.conf
    if [ "$?" -ne 0 ]; then
        echo "-----未找到nginx.conf文件-----"
        exit
    fi
}

# CentOS修改mysql密码
LNMP_CentOS_mysql(){
    mysqlpass="$(grep 'temporary password' /var/log/mysqld.log | awk '{print $11}')"
    mysql --connect-expired-password -uroot -p''$mysqlpass'' -e "alter user 'root'@'localhost' identified by '1qaz@WSX';"
    if [ "$?" -ne 0 ]; then
        echo "-----MySQL密码修改失败-----"
        exit
    fi
}

# Ubuntu修改php配置文件
LNMP_ubuntu_php(){
    sed -i "s/^post_max_size/;post_max_size/g" /etc/php/7.0/fpm/php.ini
    sed -i "s/^max_execution_time/;max_execution_time/g" /etc/php/7.0/fpm/php.ini
    sed -i "s/^max_input_time/;max_input_time/g" /etc/php/7.0/fpm/php.ini
    sed -i "s/^date.timezone/;date.timezone/g" /etc/php/7.0/fpm/php.ini
    sed -i "s/^listen/;listen/g" /etc/php/7.0/fpm/php.ini
    echo "post_max_size = 16M" >> /etc/php/7.0/fpm/php.ini
    echo "max_execution_time = 300" >> /etc/php/7.0/fpm/php.ini
    echo "max_input_time = 300" >> /etc/php/7.0/fpm/php.ini
    echo "date.timezone = "Asia/Shanghai"" >> /etc/php/7.0/fpm/php.ini
    echo "listen = 0.0.0.0:9000" >> /etc/php/7.0/fpm/php.ini
}

# CentOS修改php配置文件
LNMP_centos_php(){
    sed -i "s/^post_max_size/;post_max_size/g" /etc/php.ini
    sed -i "s/^max_execution_time/;max_execution_time/g" /etc/php.ini
    sed -i "s/^max_input_time/;max_input_time/g" /etc/php.ini
    sed -i "s/^date.timezone/;date.timezone/g" /etc/php.ini
    sed -i "s/^listen/;listen/g" /etc/php.ini
    echo "post_max_size = 16M" >> /etc/php.ini
    echo "max_execution_time = 300" >> /etc/php.ini
    echo "max_input_time = 300" >> /etc/php.ini
    echo "date.timezone = "Asia/Shanghai"" >> /etc/php.ini
    echo "extension=php_mbstring.so" >> /etc/php.ini
    echo "listen = 0.0.0.0:9000" >> /etc/php.ini
}

# Ubuntu服务添加开机自启动
LNMP_ubuntu_enable(){
    systemctl enable nginx
    systemctl enable mysql
}

# CentOS服务添加开机自启动
LNMP_centos_enable(){
    systemctl enable nginx
    systemctl enable mysqld
    systemctl enable php-fpm.service
}

# Ubuntu启动服务
LNMP_ubuntu_start(){
    systemctl start nginx
    systemctl start mysql
    service php7.0-fpm start
    systemctl restart nginx
}

# CentOS启动服务
LNMP_centos_start(){
    systemctl start nginx
    systemctl start php-fpm
    systemctl start mysqld
    systemctl restart nginx
}

# 验证lnmp部署是否成功,部署失败返回1
LNMP_check(){
    echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/info.php
    code=$(curl -I -m 10 -o /dev/null -s -w %{http_code} "http://127.0.0.1/info.php")
    if [ "${code}" -ne 200 ]; then
        echo "----------LNMP平台部署失败----------"
        return 1
    else
        echo "----------LNMP平台部署成功----------"
    fi
}

LNMP_system
num=$?
if [ "${num}" -eq 1 ]; then
    LNMP_ubuntu_init
    LNMP_ubuntu_apt
    LNMP_ubuntu_remove
    LNMP_ubuntu_install
    LNMP_ubuntu_nginx
    LNMP_ubuntu_php
    LNMP_ubuntu_enable
    LNMP_ubuntu_start
elif [ "${num}" -eq 2 ]; then
    LNMP_centos_init
    LNMP_centos_rpm
    LNMP_centos_yum
    LNMP_centos_remove
    LNMP_centos_install
    LNMP_centos_nginx
    LNMP_centos_php
    LNMP_centos_enable
    LNMP_centos_start
    LNMP_CentOS_mysql
else
    echo "-----程序结束-----"
fi

LNMP_check
check=$?
if [ "${check}" -eq 0 ]; then
    echo "--------------------"
    echo "-----MySQL账号密码-----"
    echo "IP: ${ip}"
    echo "端口：3306"
    echo "账号：root"
    echo "密码：1qaz@WSX"
    echo "----------请验证访问：http://${ip}/info.php ----------"
elif [ "${check}" -eq 1 ]; then
    exit
fi
