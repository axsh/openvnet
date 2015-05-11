class OpenvnetWebapi < FPM::Cookery::Recipe
  name     'openvnet-webapi'
  description "Web API for controlling OpenVNet"
  homepage 'https://github.com/axsh/openvnet/'
  version (ENV['BUILD_TIME'] || Time.now.strftime('%Y%m%d%H%M%S')) + (ENV['GIT_COMMIT'] ? "git#{ENV['GIT_COMMIT'].slice(0, 7)}" : "spot")
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

  post_install 'post-install.sh'

  def build
  end

  def install
    puts "*" * 50
    puts "Install OpenVNet webapi"
    opt('axsh/openvnet/vnet').install Dir["vnet/rack"]
    etc('/init').install Dir['deployment/conf_files/etc/init/vnet-webapi.conf']
    etc('/default').install Dir['deployment/conf_files/etc/default/vnet-webapi']
    etc('/openvnet').install Dir['deployment/conf_files/etc/openvnet/webapi.conf']
    puts "*" * 50
  end
end
