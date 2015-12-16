### Edit Configuration Files

Edit the file `/etc/openvnet/vnmgr.conf`

    node {
      id "vnmgr"
      addr {
        protocol "tcp"
        host "127.0.0.1"
        public ""
        port 9102
      }
    }

Modify the parameters `host` and `public` according to your environment. In order for
the sample environment in the overview section we leave those parameters as is. The detail of each parameter is following.

- **id** : OpenVNet relies on the [0mq](http://zeromq.org) protocol for communication among its processes. Hereby processes means vnmgr, vna and webapi. This id is used by 0mq to identify each process. Any string here is fine as long as there's no collision in OpenVNet. It's recommended to just use the default values.

- **protocol** : The layer 4 protocol which is either TCP or UDP. A socket which the 0mq needs will be created based on this parameter. The default value is `tcp`.

- **host** : The IP address of the vnmgr node. We use loopback address in this guide because all the processes reside on the same node .

- **public** : In case the process running in a NAT environment, specify the NAT address as the process can be reached from the outside of the NAT environment.

- **port** : The port number that the process will listen to. Specify a unique port number and make sure the port number is different for each of the OpenVNet's processes and also not taken by any other process.

`/etc/openvnet/vna.conf` and `/etc/openvnet/webapi.conf` have the same structure as `vnmgr.conf`. Edit them if necessary otherwise leave them as is for the sample environment we are just creating. We need the `id` parameter in `vna.conf` later when we configure the database. Please make sure what you specified.

