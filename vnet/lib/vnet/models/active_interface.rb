# -*- coding: utf-8 -*-

module Vnet::Models

  class ActiveInterface < Base

    plugin :paranoia_is_deleted

    many_to_one :interface
    many_to_one :datapath

    # TODO: Cleanup.

    def validate
      super
      errors.add(:label, 'must be set if singular is null') if label.nil? && singular.nil?
      errors.add(:label, 'must be set to null if singular is true') if singular == true && label
      errors.add(:singular, 'must be set to either true or null') if singular != true && !singular.nil?
    end

  end

end
