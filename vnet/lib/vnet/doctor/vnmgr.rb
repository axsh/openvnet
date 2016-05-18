# -*- coding: utf-8 -*-

module Vnet
  module Doctor
    class Vnmgr
      include Celluloid

      def examination
        results = []

        conf = Vnet::Configurations::Vnmgr.conf

        if conf.datapath_mac_group
        else
          results << [:warning,
                      "The datapath_mac_group UUID set in /etc/openvnet/common.conf. " +
                      "OpenVNet will not be able to auto-assign MAC addresses"
                     ]
        end

        results
      end
    end
  end
end

