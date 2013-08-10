class WakameVnetVna < FPM::Cookery::Recipe
  name     'wakame-vnet-vna'
  description "Virtual network agent for Wakame-VNet"
  homepage 'https://github.com/axsh/wakame-vnet/'
  version (ENV['BUILD_TIME'] || Time.now.strftime('%Y%m%d%H%M%S')) + (ENV['GIT_COMMIT'] ? "git#{ENV['GIT_COMMIT'].slice(0, 7)}" : "spot")
  #source   'https://github.com/axsh/wakame-vnet/', :with => :git
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  arch 'all'
  depends *%w(
    libpcap-devel
    openvswitch
    wakame-vnet-common
  )

  config_files *%w(
    /etc/init/vnet-vna.conf
    /etc/default/vnet-vna
    /etc/wakame-vnet/vna.conf
  )

  def build
  end

  def install
    opt('axsh/wakame-vnet/vnet/bin').install Dir["vnet/bin/vna"]
    etc('/init').install Dir['deployment/conf_files/etc/init/vnet-vna.conf']
    etc('/default').install Dir['deployment/conf_files/etc/default/vnet-vna']
    etc('/wakame-vnet').install Dir['deployment/conf_files/etc/wakame-vnet/vna.conf']
  end
end
