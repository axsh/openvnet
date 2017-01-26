# OpenVNet upgrade guide

This guide details the steps requires when upgrading from an older version of OpenVNet.

### Turn off all OpenVNet services

```bash
stop vnet-webapi
stop vnet-vnmgr
stop vnet-vna
```

### Update OpenVNet through yum.

```bash
yum update
```

### Migrate the database to the latest version.

It's likely that the database had added new tables in the new version. Update it.

```bash
PATH=/opt/axsh/openvnet/ruby/bin:${PATH}
cd /opt/axsh/openvnet/vnet
bundle exec rake db:migrate
```

### Additional steps

Some additional steps may be required if you are upgrading to a specific version.

#### Version 0.9

Version 0.9 added functionality for automatically creating `datapath_network` and `datapath_route_link` entries in the database.

This requires OpenVNet to automatically assign MAC address values for these. When upgrading to version 0.9 it is required to provide OpenVNet with a range of MAC addresses it is allowed to assign.

```bash
vnctl mac_range_groups add --uuid mrg-dpg
vnctl mac_range_groups mac_ranges add mrg-dpg --begin_mac_address 52:56:01:00:00:00 --end_mac_address 52:56:01:ff:ff:ff
```

**Remark:** If a different UUID than `mrg-dpg` is used, you must open `/etc/openvnet/common.conf` and edit the following line. `datapath_mac_group "mrg-dpg"`

### Start OpenVNet services

```bash
start vnet-webapi
start vnet-vnmgr
start vnet-vna
```
