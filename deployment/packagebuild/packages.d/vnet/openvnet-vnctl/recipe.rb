class OpenvnetVnctl < FPM::Cookery::Recipe
  name     'openvnet-vnctl'
  description 'Commandline client for making requests to OpenVNet\'s web API'
  homepage 'https://github.com/axsh/openvnet/'
  version (ENV['RPM_VERSION'] || Time.now.strftime('%Y%m%d%H%M%S'))
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  arch 'all'

  depends 'openvnet-ruby'

  config_files '/etc/openvnet/vnctl.conf'

  def build
  end

  def install
    opt('axsh/openvnet/vnctl').install Dir["vnctl/*"]
    etc('/openvnet').install 'deployment/conf_files/etc/openvnet/vnctl.conf'

    bin.install 'deployment/conf_files/usr/bin/vnctl'
  end
end
