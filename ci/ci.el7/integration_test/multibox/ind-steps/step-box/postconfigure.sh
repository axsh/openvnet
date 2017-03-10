#!/bin/bash

run_cmd "iptables -F"
run_cmd "systemctl stop firewalld"
