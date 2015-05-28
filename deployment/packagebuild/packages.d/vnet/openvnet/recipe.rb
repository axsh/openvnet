class Openvnet < FPM::Cookery::Recipe
  name     'openvnet'
  description "Virtual network agent for OpenVNet"
  homepage 'https://github.com/axsh/openvnet/'
  version (ENV['RPM_VERSION'] || Time.now.strftime('%Y%m%d%H%M%S'))
  source '', :with => :noop
  arch 'all'
  depends *%w(
    openvnet-vnmgr
    openvnet-webapi
    openvnet-vna
  )

  def build
  end

  def install
  end
end
