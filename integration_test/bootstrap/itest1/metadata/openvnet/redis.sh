#!/bin/bash

yum -y install redis

echo "service redis start" >> /etc/rc.d/rc.local
