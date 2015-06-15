#!/bin/bash
#

TEST=${1}
DIR=log/itest/current/${TEST}

LOG_DIR=${DIR}

ssh root@192.168.2.91 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest1-1-4-flows.txt" &
ssh root@192.168.2.92 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest2-1-4-flows.txt" &
ssh root@192.168.2.93 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest3-1-4-flows.txt" &
ssh root@192.168.2.91 "ssh root@10.50.0.101 \"ping -c 15 10.102.0.11\""

wait

ssh root@192.168.2.91 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest1-1-6-flows.txt" &
ssh root@192.168.2.92 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest2-1-6-flows.txt" &
ssh root@192.168.2.93 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest3-1-6-flows.txt" &
ssh root@192.168.2.91 "ssh root@10.50.0.101 \"ping -c 15 10.102.0.12\""

wait

ssh root@192.168.2.91 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest1-3-4-flows.txt" &
ssh root@192.168.2.92 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest2-3-4-flows.txt" &
ssh root@192.168.2.93 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest3-3-4-flows.txt" &
ssh root@192.168.2.92 "ssh root@10.50.0.103 \"ping -c 15 10.102.0.11\""

wait

ssh root@192.168.2.91 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest1-3-6-flows.txt" &
ssh root@192.168.2.92 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest2-3-6-flows.txt" &
ssh root@192.168.2.93 "/opt/axsh/openvnet/ruby/bin/ruby /opt/axsh/openvnet/vnet/bin/vnflows-monitor c 15 d 1 > /tmp/itest3-3-6-flows.txt" &
ssh root@192.168.2.92 "ssh root@10.50.0.103 \"ping -c 15 10.102.0.12\""

wait


scp root@192.168.2.91:/tmp/itest* ${LOG_DIR}/
scp root@192.168.2.92:/tmp/itest* ${LOG_DIR}/
scp root@192.168.2.93:/tmp/itest* ${LOG_DIR}/

