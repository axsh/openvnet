# Filters

OpenVNet supports filter rules which can be used to restrict incoming/outgoing traffic for specific interfaces.

# filters add

This page explains how to use the filter command.

```bash
vnctl filters add \
--interface-uuid if-inst1 \
--mode static \
--ingress-passthrough false \
--egress-passthrough false \
```
* interface-uuid

The interface for which the filter will be applied.

* mode

The type of filtering mode we want to used. Currently we only support static filtering, which opens/closes a port to a ip address for a specified protocol.

* ingress-passthrough

A flag that decides whether to drop or allow incoming traffic for matches with no static rule. The default setting is `false`.

* egress-passthrough

A flag that decides whether to drop or allow outgoing traffic for matches with no static rule. The default setting is `false`.

# filters static

```bash
vnctl filters static add fil-test \
--protocol tcp \
--ipv4-address 10.0.0.1 \
--port-number 21 \
--passthrough
```

Here we create a simple rule that opens up traffic for the tcp protocol on port 21.

* protocol

The protocol which we filter our traffic on.

* ipv4-address

The ip address for the rule. 0.0.0.0/0 will match all ip addresses.

* port-number

Sets port number to open/close when filtering tcp or udp traffic. 0 will match all ports.

* passthrough

A flag that decides whether to drop or allow traffic when the src/dst matches the rule. The default setting is `true`.
