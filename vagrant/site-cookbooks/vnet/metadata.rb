name             'vnet'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures vnet'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "yum"
depends "yum-epel"
depends "ntp"
depends "rbenv"
depends "sysctl"
