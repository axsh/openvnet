A Ruby library for accessing the OpenVNet WebAPI. All this library does is call Ruby's built in `Net::HTTP`. No further external libraries required.

The JSON responses from the API are returned as Ruby hashes.

Installation:

```bash
gem install vnet_api_client
```

Usage:

```ruby
require 'rubygems'
require 'vnet_api_client'

# This is the default value. If your OpenVNet WebAPI is located at localhost
# port 9090, you don't have to include this line.
VNetAPIClient.uri = 'http://localhost:9090'

# Creates a new network
VNetAPIClient::Network.create(display_name: 'my_network',
                              ipv4_network: '192.168.3.0',
                              ipv4_prefix: 24)

# Enables routing and changes display name for an interface
VNetAPIClient::Interface.update('i-abcdefg', enable_routing: true,
                                             display_name: 'my new name')

# Retrieves all datapaths
VNetAPIClient::Datapath.index

# Retrieves one interface
VNetAPIClient::Interface.show('i-abcdefg')

# Deletes one ip lease
VNetAPIClient::IpLease.delete('il-begone')

# Adds an interface to a security group
VNetAPIClient::SecurityGroup.add_interface('sg-enter', 'i-getin')

# Shows all networks in a datapath
VNetAPIClient::Datapath.show_networks('dp-mypath')

# Deletes a static address from a translation
VNetAPIClient::Translation.remove_static_address('tr-xxxxx')
```

The version number of this gem follows the version of OpenVNet. Each number has the following meaning:

[OpenVNet major version].[OpenVNet minor version].[OpenVNet hotix].[vnet_api_client gem release]

The vnet_api_client gem release number is added because it can some times be necessary to release hotfixes for the gem before a new version of OpenVNet is released.

Do note that OpenVNet's versioning scheme ommits the hotfix number if it is zero. For example if you are using OpenVNet 0.8, then you should use vnet_api_client version 0.8.0.x.
