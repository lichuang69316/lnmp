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

# Ubuntu系统卸载lnmp
LNMP_ubuntu_remove(){
    apt -y purge nginx php7.0 php7.0-fpm php7.0-mysql php7.0-common php7.0-mbstring php7.0-gd php7.0-json php7.0-cli php7.0-curl libapache2-mod-php7.0 mysql-server
}

# CentOS系统卸载lnmp
LNMP_centos_remove(){
    yum -y remove nginx php70w php70w-gd php70w-mysql php70w-fpm php70w-mbstring mysql-community-server
}

LNMP_system
num=$?
if [ "${num}" -eq 1 ]; then
    LNMP_ubuntu_remove
elif [ "${num}" -eq 2 ]; then
    LNMP_centos_remove
else
    echo "-----程序结束-----"
fi
