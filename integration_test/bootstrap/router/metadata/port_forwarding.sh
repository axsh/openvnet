#!/bin/bash

sed -i  's,^net.ipv4.ip_forward.*,net.ipv4.ip_forward = 1,' /etc/sysctl.conf
