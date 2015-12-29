# vnctl.conf

This file contains configuration that is required by `vnctl`. This one looks a little different from all other OpenVNet configuration files because `vnctl` is not an OpenVNet process like the others. It's just a simple client that makes HTTP requests to OpenVNet's Web API. This will often be installed on client machines that are actually not running OpenVNet themselves.

You'll find it at `/etc/openvnet/vnctl.conf`.

```ruby
webapi_protocol 'http'
webapi_uri  '127.0.0.1'
webapi_port '9090'
webapi_version '1.0'
output_format 'yml'
```

* webapi_protocol

The protocol used by the Web API. Currently only 'http' is supported.

* webapi_uri

The uri where the Web API is running.

* webapi_port

The TCP port that the Web API is listening on.

* webapi_version

The Web API's version. Currently '1.0' is the only version that exists.

* output_format

The format in which you want the Web API to respond. Can be either `yml` or `json`.
