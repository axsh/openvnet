### Requirements

* Vagrant
* Virtualbox
* Ruby

### Usage

install gems

```
bundle install
```

configuration

```
cp config.yml.sample config.yml
vi config.yml
```

setup vms

```
./vnet_vagrant.sh install
```

bundle install

```
cd ../; ./bin/vnspec vnet bundle_install
```

run specs

```
cd ../; ./bin/vnspec run
```
