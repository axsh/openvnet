class OpenvnetCommon < FPM::Cookery::Recipe
  name     'openvnet-common'
  description 'Common files for OpenVNet'
  homepage 'https://github.com/axsh/openvnet/'
  version (ENV['BUILD_TIME'] || Time.now.strftime('%Y%m%d%H%M%S')) + (ENV['GIT_COMMIT'] ? "git#{ENV['GIT_COMMIT'].slice(0, 7)}" : "spot")
  #source   'https://github.com/axsh/openvnet/', :with => :git
  source   File.expand_path("../../../../../", File.dirname(__FILE__)), :with => :local_path
  #arch 'all' # should be x86_64
  depends *%w(
    zeromq3-devel
    openvnet-ruby
  )

  config_files *%w(
    /etc/default/openvnet
    /etc/openvnet/common.conf
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
      opt('axsh/openvnet/vnet').install Dir["vnet/#{f}"]
    end
    opt('axsh/openvnet/vnctl').install Dir["vnctl/*"]

    etc('/default').install Dir['deployment/conf_files/etc/default/openvnet']
    etc('/openvnet').install Dir['deployment/conf_files/etc/openvnet/common.conf']

    var('run/openvnet/log').mkdir
    var('run/openvnet/pid').mkdir
    var('run/openvnet/sock').mkdir
    var('log/openvnet').mkdir
  end
end
