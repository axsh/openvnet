# The networks command explained

```bash
vnctl networks add --uuid nw-test1 --display-name testnet1 --ipv4-network 10.100.0.0 --ipv4-prefix 24 --network-mode virtual
```

* ipv4-network

The IPv4 network address.

* ipv4-prefix

The IPv4 network prefix. (default 24)

* network-mode

The mode of the network to create. We are currently creating the virtual network (10.100.0.0/24) mentioned in the figure. That is why we specify `virtual` here.
