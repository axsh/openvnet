# -*- coding: utf-8 -*-
module Vnet::NodeApi
  class Tunnel < Base
    class << self

      def update_mode(id, mode)
        transaction do
          model_class[id].tap do |obj|
            return unless obj
            obj.mode = mode
            obj.save_changes
          end
        end
      end

    end
  end
end
