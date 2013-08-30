class WakameVnet < FPM::Cookery::Recipe
  name     'wakame-vnet'
  description "Virtual network agent for Wakame-VNet"
  homepage 'https://github.com/axsh/wakame-vnet/'
  version (ENV['BUILD_TIME'] || Time.now.strftime('%Y%m%d%H%M%S')) + (ENV['GIT_COMMIT'] ? "git#{ENV['GIT_COMMIT']}" : "spot")
  source '', :with => :noop
  arch 'all'
  depends *%w(
    wakame-vnet-vnmgr
    wakame-vnet-webapi
    wakame-vnet-vna
  )

  def build
  end

  def install
  end
end
