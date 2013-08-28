class WakameVnet < FPM::Cookery::Recipe
  name     'wakame-vnet'
  description "Virtual network agent for Wakame-VNet"
  homepage 'https://github.com/axsh/wakame-vnet/'
  version  '0.0.1'
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
