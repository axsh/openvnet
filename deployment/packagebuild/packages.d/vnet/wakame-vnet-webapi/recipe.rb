class WakameVnetWebapi < FPM::Cookery::Recipe
  name     'wakame-vnet-webapi'
  description "Virtual network agent for Wakame-VNet"
  homepage 'https://github.com/axsh/wakame-vnet/'
  version  '0.0.1'
  #source   'https://github.com/axsh/wakame-vnet/', :with => :git
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  arch 'all'
  depends *%w(
    wakame-vnet-common
  )

  config_files *%w(
    /etc/init/vnet-webapi.conf
    /etc/default/vnet-webapi
    /etc/wakame-vnet/webapi.conf
  )

  def build
  end

  def install
    opt('axsh/wakame-vnet/vnet').install Dir["vnet/rack"]
    etc('/init').install Dir['deployment/conf_files/etc/init/vnet-webapi.conf']
    etc('/default').install Dir['deployment/conf_files/etc/default/vnet-webapi']
    etc('/wakame-vnet').install Dir['deployment/conf_files/etc/wakame-vnet/webapi.conf']
  end
end
