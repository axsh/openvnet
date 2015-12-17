# vna.conf

This file contains the configuration used by `vna`.

You'll find it at `/etc/openvnet/vna.conf`.

It contains two sections.

## Node

This is similar to the node sections found in other config files. It's all the information OpenVNet needs to enable this vna to communicate with all other OpenVNet processes.

```ruby
node {
  id "vna"
  addr {
    protocol "tcp"
    host "127.0.0.1"
    public ""
    port 9103
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

## Network

This lets OpenVNet know what physical network this VNA is in. Whe installing OpenVNet on a single machine like we do in the [installation guide](../installation), this section can be left empty.

```ruby
network {
  uuid ""
  gateway {
    address ""
  }
}
```

* uuid

The uuid of the public/physical network in which the vna participates.

* address

The gateway address of the network specified by the 'uuid'.
