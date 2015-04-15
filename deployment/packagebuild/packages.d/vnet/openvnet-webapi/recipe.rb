class OpenvnetWebapi < FPM::Cookery::Recipe
  name     'openvnet-webapi'
  description "Virtual network agent for OpenVNet"
  homepage 'https://github.com/axsh/openvnet/'
  version (ENV['BUILD_TIME'] || Time.now.strftime('%Y%m%d%H%M%S')) + (ENV['GIT_COMMIT'] ? "git#{ENV['GIT_COMMIT'].slice(0, 7)}" : "spot")
  #source   'https://github.com/axsh/openvnet/', :with => :git
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  arch 'all'
  depends *%w(
    openvnet-common
  )

  config_files *%w(
    /etc/init/vnet-webapi.conf
    /etc/default/vnet-webapi
    /etc/openvnet/webapi.conf
  )

  post_install 'post-install'

  def build
  end

  def install
    opt('axsh/openvnet/vnet').install Dir["vnet/rack"]
    etc('/init').install Dir['deployment/conf_files/etc/init/vnet-webapi.conf']
    etc('/default').install Dir['deployment/conf_files/etc/default/vnet-webapi']
    etc('/openvnet').install Dir['deployment/conf_files/etc/openvnet/webapi.conf']
  end
end
