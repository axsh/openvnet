### Requirements

* Ruby(2.0 or later)
* Virtualbox
* Vagrant(1.5 or later)

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
