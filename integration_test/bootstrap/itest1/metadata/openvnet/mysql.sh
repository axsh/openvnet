#!/bin/bash

yum -y install mysql-server

echo "service mysqld start" >> /etc/rc.d/rc.local
