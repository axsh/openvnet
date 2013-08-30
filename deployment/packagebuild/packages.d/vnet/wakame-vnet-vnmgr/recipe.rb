class WakameVnetVnmgr < FPM::Cookery::Recipe
  name     'wakame-vnet-vnmgr'
  description "Virtual network agent for Wakame-VNet"
  homepage 'https://github.com/axsh/wakame-vnet/'
  version  '0.0.1'
  #source   'https://github.com/axsh/wakame-vnet/', :with => :git
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  arch 'all'
  depends *%w(
    redis
    mysql-server
    wakame-vnet-common
  )

  config_files *%w(
    /etc/init/vnet-vnmgr.conf
    /etc/default/vnet-vnmgr
    /etc/wakame-vnet/vnmgr.conf
  )

  def build
  end

  def install
    puts "*" * 50
    opt('axsh/wakame-vnet/vnet/bin').install Dir["vnet/bin/vnmgr"]
    etc('/init').install Dir['deployment/conf_files/etc/init/vnet-vnmgr.conf']
    etc('/default').install Dir['deployment/conf_files/etc/default/vnet-vnmgr']
    etc('/wakame-vnet').install Dir['deployment/conf_files/etc/wakame-vnet/vnmgr.conf']
    puts "*" * 50
  end
end
