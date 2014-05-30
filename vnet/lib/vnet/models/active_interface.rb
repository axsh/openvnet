# -*- coding: utf-8 -*-

module Vnet::Models

  class ActiveInterface < Base
    many_to_one :interface
    many_to_one :datapath

    def validate
      super
      errors.add(:label, 'must be set if singular is null') if label.nil? && singular.nil?
      errors.add(:singular, 'must be set to either true or null') if singular != true && !singular.nil?
    end

  end

end
