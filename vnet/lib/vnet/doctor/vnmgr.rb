# -*- coding: utf-8 -*-

module Vnet
  module Doctor
    class Vnmgr
      include Celluloid

      def examination
        [
          [:success, "success tested"],
          [:success, "another success tested"],
          [:failure, "failure tested"],
        ]
      end
    end
  end
end

