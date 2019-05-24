# -*- coding: utf-8 -*-

# Remove top-level :array and :string methods introduced by trema-edge
# to avoid the conflict with BinData's primitive methods.
Class.class_eval { undef_method :array } rescue NameError
Class.class_eval { undef_method :string } rescue NameError

module Vnet::Endpoints::V10::Helpers
  E = Vnet::Endpoints::Errors

  module ClassMethods
    def load_namespace(ns)
      fname = File.expand_path("#{ns}.rb", File.dirname(caller.first.split(':').first))
      #::Kernel.load fname
      # workaround for Rubinius
      class_eval(File.read(fname), fname)
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  module UUID
    def self.regex(prefix)
      /^#{prefix}-[a-z0-9]{1,16}$/
    end

    def pop_uuid(model, key = 'uuid', fill = {})
      uuid = @params.delete(key)
      check_uuid_syntax(model, uuid, key)
      model.batch[uuid].commit(:fill => fill) || raise(E::UnknownUUIDResource, "#{model.name.split('::').last}##{key}: #{uuid}")
    end

    def pop_uuid_or_nil(model, key = 'uuid', fill = {})
      uuid = @params.delete(key) || return
      check_uuid_syntax(model, uuid, key)
      model.batch[uuid].commit(:fill => fill)
    end

    def check_uuid_syntax(model, uuid, key = 'uuid')
      model.valid_uuid_syntax?(uuid) || raise(E::InvalidUUID, "#{model.name.split('::').last}##{key}: #{uuid}")
    end

    def check_and_trim_uuid(model)
      raise E::DuplicateUUID, @params['uuid'] unless model[@params['uuid']].nil?
      @params['uuid'] = model.trim_uuid(@params['uuid'])
    end

    # Deprecated:
    def check_syntax_and_pop_uuid(model, key = 'uuid', fill = {})
      check_uuid_syntax(model, @params[key], key)
      pop_uuid(model, key, fill)
    end

    # Deprecated:
    def check_syntax_and_get_id(model, uuid_key = 'uuid', id_key = 'id', fill = {})
      check_uuid_syntax(model, @params[uuid_key], uuid_key)
      uuid_to_id(model, uuid_key, id_key, fill)
    end

    def uuid_to_id(model, uuid_key = 'uuid', id_key = 'id', fill = {})
      model = pop_uuid(model, uuid_key, fill)
      model.id || raise(E::InvalidID, "#{model.name.split('::').last}##{uuid_key}: #{uuid}")

      @params[id_key] = model.id

      model
    end

    def uuid_to_id_or_nil(model, uuid_key = 'uuid', id_key = 'id', fill = {})
      model = pop_uuid_or_nil(model, uuid_key, fill) || return
      model.id || raise(E::InvalidID, "#{model.name.split('::').last}##{uuid_key}: #{uuid}")

      @params[id_key] = model.id

      model
    end

  end

  module Parsers
    PARSE_IPV4 = proc do |param|
      begin
        Pio::IPv4Address.new(param).to_i
      rescue IPAddr::InvalidAddressError
        raise(E::ArgumentError, "Could not parse IPv4 address: #{param}")
      end
    end

    PARSE_MAC = proc do |param|
      begin
        Pio::Mac.new(param).to_i
      rescue Pio::Mac::InvalidValueError
        raise(E::ArgumentError, "Could not parse MAC address: #{param}")
      end
    end

    PARSE_IPV4_ADDRESS = proc do |param|
      begin
        Pio::IPv4Address.new(param)
      rescue IPAddr::InvalidAddressError
        raise(E::ArgumentError, "Could not parse IPv4 address: #{param}")
      end
    end
  end
end
