# Feature list

* Two protocols to support virtual networking.
*   - **MAC2MAC** (Axsh original protocol for physical L2 tunneling)
*   - **GRE** (protocol for L3 tunneling)
* Simulated DHCP service
* Simulated DNS service
* L3 routing between virtual networks.
* Single hop L3 routing between physical and virtual networks.
* Firewall (security groups)
* Connection tracking
* One to one static network address translation. (SNAT)
* VNet Edge feature (connect virtual and physical networks)
* RESTful Web API
* Commandline interface (vnctl) for calling the Web API.
* Integration with [Wakame-vdc](http://wakame-vdc.org).
* A [Ruby library (gem)](https://rubygems.org/gems/vnet_api_client) that will allow you to call the Web API directly from ruby applications.
