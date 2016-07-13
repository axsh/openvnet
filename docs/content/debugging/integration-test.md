# Integration test

We have an integration test environment set up for OpenVNet on which we *always* test code changes before merging them. The environment looks like this.

![Integration test topology](https://github.com/axsh/wakame-ci-cluster/raw/master/kvm-guests/90-vteskins/draw/network_structure.png)

As you can see this is a pretty complicated environment. It consists of multiple KVM virtual machines, several of which have Open vSwitch and VNA running. Then there's others that act as [traditional networks](../jargon-dictionary#traditional-network), allowing us to test [VNet Edge](../jargon-dictionary#vnet-edge) among other things.

This environment is portable and you can try setting it up for yourself but be aware that you will require a Linux machine capable of nested KVM. The setup scripts along with a README file can be found on [our wakame-ci-cluster repository](https://github.com/axsh/wakame-ci-cluster/tree/master/kvm-guests/90-vteskins) on github.

Even if you don't set up the integration test for yourself, it can provide examples of how different virtual network topologies are set up.

While the test environment setup scripts can be found in the wakame-ci-cluster repository, the test code itself is located [in the OpenVNet repository](https://github.com/axsh/openvnet/tree/master/integration_test) itself.

The dataset directory in there contains yaml files that translate directly to `vnctl` commands. The file [dataset/base.yml](https://github.com/axsh/openvnet/blob/master/integration_test/dataset/base.yml) will show you you how to configure a multi-host OpenVNet setup. While all the other files in that directory create various virtual network topologies.

Figuring out the integration test environment can be a daunting task at first but it's the best resource after completing the guides on this site. Good luck.
