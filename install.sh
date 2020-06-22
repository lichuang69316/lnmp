#!/bin/bash

system=$(awk -F '=' 'NR==3{print $2}' /etc/os-release)
mysql_passwd = mysqlpass="$(grep 'temporary password' /var/log/mysqld.log | awk '{print $11}')"
workdir=$(dirname "$0")

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
    pass
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
    rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
    if [ "$?" -ne 0 ]; then
        echo "----------安装yum源失败，可能是网络的原因----------"
        exit
    fi
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
    yum-config-manager --enable rhel-7-server-optional-rpms
    if [ "$?" -ne 0 ]; then
        echo "----------安装已经更新包失败，可能是网络或者本地不能使用yum的原因----------"
        exit
    fi
}

# CentOS清除旧的包
LNMP_centos_remove(){
    yum -y remove nginx php-common php* mariadb*
}

# CentOS安装LNMP环境
LNMP_centos_install(){
    yum -y install nginx
    yum -y install php70w php70w-gd php70w-mysql php70w-fpm php70w-mbstring
    yum -y install mysql-community-server
}

# CentOS修改nginx配置文件
LNMP_centos_nginx(){
    mv /etc/nginx/conf/nginx.conf /etc/nginx/conf/nginx.conf_bak
    cp -rf ${workdir}/nginx.conf /etc/nginx/conf/nginx.conf
    if [ "$?" -ne 0 ]; then
        echo "-----未找到nginx.conf文件-----"
        exit
    fi
}

# CentOS修改mysql密码
LNMP_centos_mysql(){
    mysql --connect-expired-password -uroot -p''$mysqlpass'' -e "alter user 'root'@'localhost' identified by '1qaz@WSX';"
    if [ "$?" -ne 0 ]; then
        echo "-----MySQL密码修改失败-----"
        exit
    fi
}

# CentOS修改php配置文件
LNMP_centos_php(){
    sed -i "s/^post_max_size/;post_max_size/g" /etc/php.ini
    sed -i "s/^max_execution_time/;max_execution_time/g" /etc/php.ini
    sed -i "s/^max_input_time/;max_input_time/g" /etc/php.ini
    sed -i "s/^date.timezone/;date.timezone/g" /etc/php.ini
    echo "post_max_size = 16M" >> /etc/php.ini
    echo "max_execution_time = 300" >> /etc/php.ini
    echo "max_input_time = 300" >> /etc/php.ini
    echo "date.timezone = "Asia/Shanghai"" >> /etc/php.ini
    echo "extension=php_mbstring.so" >> /etc/php.ini
}

# CentOS服务添加开机自启动
LNMP_centos_enable(){
    systemctl enable nginx
    systemctl enable mysqld
    systemctl enable php-fpm.service
}

# CentOS启动服务
LNMP_centos_start(){
    systemctl start nginx
    systemctl start php-fpm
    systemctl start mysqld
}

# 验证lnmp部署是否成功
LNMP_check(){
    echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/info.php
    code=$(curl -I -m 10 -o /dev/null -s -w %{http_code} "http://127.0.0.1/info.php")
    if [ "${code}" -ne 200 ]; then
        echo "----------LNMP平台部署失败----------"
    else
        echo "----------LNMP平台部署成功----------"
    fi
}

LNMP_system
num=$?
if [ "${num}" -eq 1 ]; then
    LNMP_ubuntu_init
    echo "----------脚本还未完善，目前仅支持Centos系统----------"
elif [ "${num}" -eq 2 ]; then
    LNMP_centos_init
    LNMP_centos_rpm
    LNMP_centos_yum
    LNMP_centos_remove
    LNMP_centos_install
    LNMP_centos_nginx
    LNMP_centos_mysql
    LNMP_centos_php
    LNMP_centos_enable
    LNMP_centos_start
else
    echo "-----程序结束-----"
fi

LNMP_check
