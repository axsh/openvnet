class WakameVnetCommon < FPM::Cookery::Recipe
  name     'wakame-vnet-common'
  description 'Common files for Wakame-VNet'
  homepage 'https://github.com/axsh/wakame-vnet/'
  version (ENV['BUILD_TIME'] || Time.now.strftime('%Y%m%d%H%M%S')) + (ENV['GIT_COMMIT'] ? "git#{ENV['GIT_COMMIT'].slice(0, 7)}" : "spot")
  #source   'https://github.com/axsh/wakame-vnet/', :with => :git
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  arch 'all'
  depends *%w(
    zeromq-devel
    wakame-vnet-ruby
  )

  config_files *%w(
    /etc/default/wakame-vnet
    /etc/wakame-vnet/common.conf
  )

  def build
  end

  def install
    %w(
      Gemfile
      Gemfile.lock
      LICENSE
      README.md
      Rakefile
      db
      lib
      vendor
      .bundle
    ).each do |f|
      opt('axsh/wakame-vnet/vnet').install Dir["vnet/#{f}"]
    end
    opt('axsh/wakame-vnet/vnctl').install Dir["vnctl/*"]

    etc('/default').install Dir['deployment/conf_files/etc/default/wakame-vnet']
    etc('/wakame-vnet').install Dir['deployment/conf_files/etc/wakame-vnet/common.conf']

    var('run/wakame-vnet/log').mkdir
    var('run/wakame-vnet/pid').mkdir
    var('run/wakame-vnet/sock').mkdir
    var('log/wakame-vnet').mkdir
  end
end
