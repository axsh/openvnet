# -*- coding: utf-8 -*-

module Vnet
  module Doctor
    class Vnmgr
      include Celluloid

      def examination
        results = []

        conf = Vnet::Configurations::Vnmgr.conf

        if mg_uuid = conf.datapath_mac_group
          if Vnet::Models::MacRangeGroup[mg_uuid]
            results << [:success,
                        "The datapath_mac_group UUID was set and found in the database. " +
                        "OpenVNet will be able to auto-assign MAC addresses"
                       ]
          else
            results << [:warning,
                        "The datapath_mac_group UUID set in /etc/openvnet/common.conf " +
                        "was not found in the database. " +
                        "OpenVNet will not be able to auto-assign MAC addresses."
                       ]
          end
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

