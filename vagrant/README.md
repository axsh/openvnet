### Requirements

* Ruby(2.0 or later)
* Virtualbox
* Vagrant(1.5 or later)

### Install

install vagrant plugins

```
vagrant plugin install vagrant-omnibus
```

install gems

```
bundle install
```

install cookbooks

```
bundle exec berks vendor cookbooks
```

configure ssh(default identity_file is ~/.vagrant.d/insecure_private_key)

```
./ssh_config [IDENTIFY_FILE]
```

setup vms

```
vagrant up
```

if `vagrant up` failed on provisioning, run following command.

```
vagrant provision
```

run specs

```
cd ../; ./bin/vnspec run
```

rsync vnet source code

src: host
```
./share/bin/vnet-sync-auto PATH_TO_OPENVNET
```

src: vm(vnmgr)
```
ssh vnmgr nohup ./share/bin/vnet-sync-auto PATH_TO_OPENVNET &
```
