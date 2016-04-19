# common.conf

This file contains common configuration that is used by `vnmgr`, `webapi` and `vna`.

You'll find it at `/etc/openvnet/vnmgr.conf`.

It is divided into the following sections.

## Registry

This is the key-value storage that the [DCell framework](https://github.com/celluloid/dcell) requires. OpenVNet's services use DCell to communicate with each other.

```ruby
registry {
  adapter "redis"
  host "127.0.0.1"
  port 6379
}
```

* adapter

The name of key-value store. Defalut value is 'redis'.

* host

IP address of the key-value store.

* port

TCP port that the key-value process is listening on.

## DB

This holds all the information OpenVNet needs to connect to its [MySQL](https://www.mysql.com) database.

```ruby
db {
  adapter "mysql2"
  host "localhost"
  database "vnet"
  port 3306
  user "root"
  password ""
}
```


* adapter

The adapter name for the database. OpenVNet only support `mysql` at this time.

* host

IP address of the db server.

* database

The name of the database.

* port

Listen port of the db server.

* user

User name of the db server.

* password

Password of the db server.

## Misc

```ruby
datapath_mac_group "mrg-dpg"
```

* datapath_mac_group

Contains the UUID of the mac range group used for `datapath_network` and `datapath_route_link` mac addresses.
