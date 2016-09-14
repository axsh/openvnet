# -*- coding: utf-8 -*-

module Vnet

  class ItemBase
    include Celluloid::Logger
    include Vnet::LookupParams

    MW = Vnet::ModelWrappers

    attr_reader :id
    attr_reader :installed
    attr_reader :loaded
    attr_reader :invalid

    def initialize(params)
      @installed = false
      @loaded = false
    end

    def installed?
      @installed == true
    end

    # Loaded can be true even if the item is going through unload, and
    # has been unloaded.
    def loaded?
      @loaded == true
    end

    def invalid?
      @invalid == true
    end

    def install
    end

    def uninstall
    end

    def try_install
      (@installed == false) && install
      return if @invalid == true
      @installed = true
    end

    def try_uninstall
      @installed, was_installed = false, @installed
      (was_installed == true) && uninstall
    end

    def set_loaded
      @loaded = true
    end

    def pretty_id
      "#{@id}"
    end

    def pretty_properties
      nil
    end

    def to_hash
      raise NotImplementedError
    end

    def log_type
      raise NotImplementedError
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{log_type}: #{message}" + (values ? " (#{values})" : '')
    end

    def log_format_h(message, values)
      str = values.map { |value|
        value.join(':')
      }.join(' ')

      log_format(message, str)
    end

  end

  class ItemVnetBase < ItemBase
    def initialize(params)
      @installed = false
      @loaded = false

      @id = get_param_id(params)
    end
  end

  class ItemVnetUuid < ItemVnetBase
    attr_reader :uuid

    def initialize(params)
      @installed = false
      @loaded = false

      map = get_param_map(params)
      @id = get_param_id(map)
      @uuid = get_param_string(map, :uuid)
    end

    def pretty_id
      "#{@uuid}/#{@id}"
    end
  end

  # TODO: This class isn't really correctly implemented, replace the
  # initialize method with a not-implemented exception and create a
  # different ItemDpId32 for e.g. ports. 
  class ItemDpBase < ItemBase
    def initialize(params)
      @installed = false
      @loaded = false

      @dp_info = get_param_dp_info(params)
      @id = get_param_id_32(params)
    end

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} #{log_type}: #{message}" + (values ? " (#{values})" : '')
    end
  end

  class ItemDpId < ItemDpBase
    def initialize(params)
      @installed = false
      @loaded = false

      @dp_info = get_param_dp_info(params)
      @id = get_param_id(get_param_map(params))
    end
  end

  class ItemDpUuid < ItemDpBase
    attr_reader :uuid

    def initialize(params)
      @installed = false
      @loaded = false

      @dp_info = get_param_dp_info(params)

      map = get_param_map(params)
      @id = get_param_id(map)
      @uuid = get_param_string(map, :uuid)
    end

    def pretty_id
      "#{@uuid}/#{@id}"
    end
  end

  class ItemDpUuidMode < ItemDpUuid
    attr_reader :mode

    def initialize(params)
      @installed = false
      @loaded = false

      @dp_info = get_param_dp_info(params)

      map = get_param_map(params)
      @id = get_param_id(map)
      @uuid = get_param_string(map, :uuid)
      @mode = get_param_string(map, :mode).to_sym
    end

    def pretty_properties
      "mode:#{@mode}"
    end
  end

end
