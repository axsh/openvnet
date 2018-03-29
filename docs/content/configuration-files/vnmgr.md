# vnmgr.conf

This file contains the configuration used by `vnmgr`.

You'll find it at `/etc/openvnet/vnmgr.conf`.

```ruby
node {
  id "vnmgr"
  addr {
    protocol "tcp"
    host "127.0.0.1"
    public ""
    port 9102
  }
}
```

* id

The ID of the OpenVNet's process. It should be unique among the entire world of the OpenVNet.

* protocol

This parameter can be used to specify the 0MQ address. Default value is 'tcp'.

* host

Private IP address that can be used to specify the 0MQ address.

* public

Public/Global IP address that is linked to the private IP address specified by the 'host' parameter. A 0MQ socket will be created with the public/global IP address if this paramter is specified. Otherwise 'host' parameter will be used to create a 0MQ socket.

* port

Listen port of the process.
