class WakameVnet < FPM::Cookery::Recipe
  name     'openvnet'
  description "Virtual network agent for OpenVNet"
  homepage 'https://github.com/axsh/openvnet/'
  version (ENV['BUILD_TIME'] || Time.now.strftime('%Y%m%d%H%M%S')) + (ENV['GIT_COMMIT'] ? "git#{ENV['GIT_COMMIT'].slice(0, 7)}" : "spot")
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
