#!/bin/bash

yum -y install redis

sed -i 's/bind/#bind/g' /etc/redis.conf

echo "service redis start" >> /etc/rc.d/rc.local
