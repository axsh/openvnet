class Openvswitch < FPM::Cookery::Recipe
  description 'Open vSwitch (Recent Release)'

  name     'wakame-vnet-openvswitch'
  version  '1.10.0'
  homepage 'http://openvswitch.org/'
  source   "http://openvswitch.org/releases/openvswitch-#{version}.tar.gz"
  sha256   '803966c89d6a5de6d710a2cb4ed73ac8d8111a2c44b12b846dcef8e91ffab167'

  platforms [:redhat, :centos] do
    build_depends 'libpcap-devel', 'kernel-devel', 'gcc', 'openssl-devel', 'redhat-rpm-config', 'dracut-kernel'
  end
  platforms [:debian, :ubuntu] do
    build_depends 'libpcap-dev', 'linux-headers', 'libssl-dev', 'gcc'
  end

  def build
    configure :prefix => prefix
    make
  end

  def install
    make :install, 'DESTDIR' => destdir
  end
end
