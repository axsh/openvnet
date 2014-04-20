### Requirements

* Ruby(2.0 or later)
* Virtualbox
* Vagrant(1.5 or later)

### Usage

install gems

```
bundle install
```

configure ssh

```
./ssh_config [IDENTIFY_FILE]
```

install cookbooks

```
bundle exec berks vendor cookbooks
```

setup vms

```
vagrant up
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
