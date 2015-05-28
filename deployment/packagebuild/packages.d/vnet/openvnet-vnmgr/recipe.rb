class OpenvnetVnmgr < FPM::Cookery::Recipe
  name     'openvnet-vnmgr'
  description "Virtual network agent for OpenVNet"
  homepage 'https://github.com/axsh/openvnet/'
  version (ENV['RPM_VERSION'] || Time.now.strftime('%Y%m%d%H%M%S'))
  #source   'https://github.com/axsh/openvnet/', :with => :git
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  arch 'all'
  depends *%w(
    redis
    mysql-server
    openvnet-common
  )

  config_files *%w(
    /etc/init/vnet-vnmgr.conf
    /etc/default/vnet-vnmgr
    /etc/openvnet/vnmgr.conf
  )

  post_install 'post-install.sh'

  def build
  end

  def install
    puts "*" * 50
    puts "Install OpenVNet vnmgr"
    opt('axsh/openvnet/vnet/bin').install Dir["vnet/bin/vnmgr"]
    etc('/init').install Dir['deployment/conf_files/etc/init/vnet-vnmgr.conf']
    etc('/default').install Dir['deployment/conf_files/etc/default/vnet-vnmgr']
    etc('/openvnet').install Dir['deployment/conf_files/etc/openvnet/vnmgr.conf']
    puts "*" * 50
  end
end
