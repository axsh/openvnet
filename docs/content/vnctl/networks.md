# networks add

```bash
vnctl networks add \
  --uuid nw-test1 \
  --display-name testnet1 \
  --ipv4-network 10.100.0.0 \
  --ipv4-prefix 24 \
  --network-mode virtual
```
* uuid

A unique ID that will be used to refer to this network.

* display-name

A human readable name that describes this network. It can be anything you want.

* ipv4-network

The IPv4 network address. Basically the first part (before the slash) of a CIDR notation. For `10.0.0.0/8` the network address would be `10.0.0.0`.

* ipv4-prefix (default 24)

The IPv4 network prefix. The part after the slash of a CIDR notation. For `10.0.0.0/8`, the prefix would be 8.

* network-mode

The mode of the network to create. In the example we are creating a virtual network to connect virtual machines to. Therefore we specify `virtual`.

If we were to be creating a network that OpenVNet will use behind the scenes to send traffic between different hosts running Open vSwitch, we would specify `physical` instead.
