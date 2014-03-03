class WakameVnetRuby < FPM::Cookery::Recipe
  description 'The Ruby virtual machine(For Wakame-VNET bundle)'

  name 'wakame-vnet-ruby'
  version '2.1.1'
  revision 0
  homepage 'http://www.ruby-lang.org/'
  source "http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-#{version.split('.')[0,3].join('.')}.tar.bz2"

  vendor     'axsh'
  license    'The Ruby License'

  section 'interpreters'

  platforms [:debian, :ubuntu] do
    build_depends 'autoconf', 'bison', 'zlib1g-dev', 'libssl-dev', 'libyaml-dev',
    'libffi-dev', 'libgdbm-dev', 'libncurses5-dev', 'libreadline6-dev', 'chrpath',
    'libxml2-dev', 'libxslt1-dev'

    depends 'libffi6', 'libssl1.0.0', 'libtinfo5', 'libyaml-0-2', 'zlib1g', 'libgdbm3',
    'libncurses5', 'libreadline6', 'libxml2', 'libxslt1.1'
  end

  platforms [:redhat, :centos] do
    build_depends 'autoconf', 'bison', 'zlib-devel', 'libxml2-devel', 'libxslt-devel',
    'openssl-devel', 'libyaml-devel', 'libffi-devel', 'gdbm-devel', 'ncurses-devel',
    'readline-devel', 'chrpath', 'rpmdevtools'

    depends 'libffi', 'ncurses-libs', 'openssl', 'libyaml', 'zlib', 'gdbm', 'readline',
    'libxml2', 'libxslt'
  end

  def build
    ENV['CFLAGS']="-O0 -ggdb3 -Wall"
    configure :prefix => prefixdir, :sysconfdir => '/etc',
      'disable-install-doc' => true

    make
  end

  def install
    make :install, :DESTDIR => destdir
    gem 'install', 'bundler', '--no-ri', '--no-rdoc'
    safesystem 'bash', '-c', <<EOF
for i in $(find #{destdir} -type f -and -executable); do
  if file -b "$i" | grep -q '^ELF ' > /dev/null; then
    chrpath --replace /opt/axsh/wakame-vnet/ruby/lib "$i" || :
  fi
done
EOF
    # rewrite shebang.
    Dir["#{destprefixdir}/bin/**"].each { |path|
      if `file -b #{path}` =~ /script text executable$/
        inline_replace(path, /^#!#{destdir}.*/, "#!/opt/axsh/wakame-vnet/ruby/bin/ruby")
      end
    }
  end

  private
  def prefixdir
    '/opt/axsh/wakame-vnet/ruby'
  end

  def destprefixdir
    "#{destdir}/#{prefixdir}"
  end

  # Run gem command in 'destdir'. It helps to install gems to the system
  # gems directory.
  #
  # gem 'install', 'bundler'
  def gem(*args)
    # TODO: preserve original env values.
    ENV['RUBYLIB']=`find #{destprefixdir}/lib/ruby -maxdepth 2 -type d`.split.join(':')
    cleanenv_safesystem(File.expand_path('bin/ruby', destprefixdir), File.expand_path('bin/gem', destprefixdir), *args)
  end
end
