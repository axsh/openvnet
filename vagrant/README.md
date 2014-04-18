### Requirements

* Ruby(2.0 or later)
* Virtualbox
* Vagrant(1.5 or later)

### Usage

install gems

```
bundle install
```

setup vms

```
./vnet_vagrant.sh install
```

run specs

```
cd ../; ./bin/vnspec run
```

rsync vnet source code

src: host
```
./share/bin/vnet-sync-auto ${path_to_openvnet}
```

src: vm(vnmgr)
```
ssh vnmgr nohup /vagrant/share/bin/vnet-sync-auto &
```
