# Troubleshooting

So something went wrong. What should you do?

## Make sure all required services are running

```bash
service mysqld status
service redis status

initctl status vnet-vnmgr
initctl status vnet-webapi
initctl status vnet-vna
```

If any of these services are not running, start them. Make sure that they are still running after starting them. It is possible for a service to start successfully but go down again immediately afterwards.

If any of these services aren't starting correctly, look for clues in the log files in `/var/log/openvnet`.

## Make sure the database exists and is populated.

```bash
mysql -u root

use vnet;
show tables;
```

If the database or tables don't exist, set it up as specified in the [installation guide](../installation#setup-database).

## Double check all vnctl commands

Mistakes are easily made. Review your vnctl commands carefully and make sure you didn't make any typos.

## Check if VNA is connected to Open vSwitch

Run `ovs-vsctl show`. The output should look similar to this.

```bash
54b868bc-04fa-44d7-831a-00cb8eff7ee2
    Bridge "br0"
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: secure
        Port "inst2"
            Interface "inst2"
        Port "br0"
            Interface "br0"
                type: internal
        Port "inst1"
            Interface "inst1"
    ovs_version: "2.3.1"
```

If you are missing the `is_connected: true` line then VNA isn't connected to Open vSwitch. In that case, run the following command.

```bash
vnctl datapaths show
```

Its output should contain something similar to the following.

```yaml
- :id: 1
  :uuid: dp-test1
  :display_name: test1
  :dpid: '0x0000aaaaaaaaaaaa'
  :node_id: vna
  :is_connected: false
  :created_at: 2015-12-18 04:13:28.000000000 Z
  :updated_at: 2015-12-18 04:13:28.000000000 Z
  :deleted_at:
  :is_deleted: 0
```

Check if the `node_id` in there is the same as the one defined in `/etc/openvnet/vna.conf`.

Also check the `dpid`. It should be the same as outputted the following command.

```bash
ovs-vsctl list bridge | grep datapath_id
```

If the above command outputted more than one line, you have more than one bridge set up with Open vSwitch. Make sure the correct one is registered with OpenVnet.

If either of these need to be changed you can do so with the following command.

```bash
vnctl datapaths modify dp-test1 --dpid 0xdeadbeefdeadbeef --node-id foobar
```

## Check if Open vSwitch's ports are connected

Run the `ovs-vsctl show` command again. Like in the section above, the output should look similar to this.

```bash
54b868bc-04fa-44d7-831a-00cb8eff7ee2
    Bridge "br0"
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: secure
        Port "inst2"
            Interface "inst2"
        Port "br0"
            Interface "br0"
                type: internal
        Port "inst1"
            Interface "inst1"
    ovs_version: "2.3.1"
```

If you followed the installation guide, the ports `inst1` and `inst2` should be there. If not, add them as specified [in the guide](../installation#attach-them-to-open-vswitch).

If Open vSwitch was shut down incorrectly in the past, it's possible for ports to show up even when they're not really connected. In that case try removing and re-adding them.

```bash
ovs-vsctl del-port br0 inst1
ovs-vsctl del-port br0 inst2

ovs-vsctl add-port br0 inst1
ovs-vsctl add-port br0 inst2
```

## Use tcpdump

Tcpdump is a very useful tool for debugging networks. You can install it on Centos with the following command.

```bash
yum install tcpdump
```

There are many tutorials out there on how to use it. Have your network setup do some actions (like ping) that you think should work and use tcpdump to figure out exactly where things go wrong.

## Use vnflows-monitor

So you've used tcpdump and noticed that it's inside Open vSwitch that things are going wrong? In that case OpenVNet is probably configured incorrectly. You can use the vnflows-monitor debug tool to see exactly which flows get matched and figure where things go wrong. Read more about vnflows-monitor in [its own guide](vnflows-monitor).

## Contact us

So you've tried everything and just can't figure it out? Contact us on the [Wakame Users Group](https://groups.google.com/forum/#!forum/wakame-ug). We are very busy and might not be able to reply right away but we will do our very best to help you.
