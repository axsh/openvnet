class OpenvnetVna < FPM::Cookery::Recipe
  name     'openvnet-vna'
  description "Virtual network agent for OpenVNet"
  homepage 'https://github.com/axsh/openvnet/'
  version (ENV['BUILD_TIME'] || Time.now.strftime('%Y%m%d%H%M%S')) + (ENV['GIT_COMMIT'] ? "git#{ENV['GIT_COMMIT'].slice(0, 7)}" : "spot")
  #source   'https://github.com/axsh/openvnet/', :with => :git
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  arch 'all'
  depends *%w(
    libpcap-devel
    openvswitch
    openvnet-common
  )

  config_files *%w(
    /etc/init/vnet-vna.conf
    /etc/default/vnet-vna
    /etc/openvnet/vna.conf
  )

  post_install 'post-install.sh'

  def build
  end

  def install
    opt('axsh/openvnet/vnet/bin').install Dir["vnet/bin/vna"]
    opt('axsh/openvnet/vnet/bin').install Dir["vnet/bin/vnflows-monitor"]
    etc('/init').install Dir['deployment/conf_files/etc/init/vnet-vna.conf']
    etc('/default').install Dir['deployment/conf_files/etc/default/vnet-vna']
    etc('/openvnet').install Dir['deployment/conf_files/etc/openvnet/vna.conf']
  end
end
