# -*- coding: utf-8 -*-
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
    def pop_uuid(model, params, key = "uuid", fill = {})
      uuid = params.delete(key)
      model.batch[uuid].commit(:fill => fill) || raise(E::UnknownUUIDResource, "#{model.name.split("::").last}##{key}: #{uuid}")
    end

    def check_uuid_syntax(model, uuid)
      model.valid_uuid_syntax?(uuid) || raise(E::InvalidUUID, "#{model.name.split("::").last}#uuid: #{uuid}")
    end

    def check_and_trim_uuid(model, params)
      raise E::DuplicateUUID, params["uuid"] unless model[params["uuid"]].nil?
      params["uuid"] = model.trim_uuid(params["uuid"])
    end

    def check_syntax_and_pop_uuid(model, params, key = "uuid", fill = {})
      check_uuid_syntax(model, params[key])
      pop_uuid(model, params, key, fill)
    end

    def check_syntax_and_get_id(model, params, uuid_key = "uuid", id_key = "id", fill = {})
      check_uuid_syntax(model, params[uuid_key])
      uuid_to_id(model, uuid_key, id_key, fill)
    end

    def uuid_to_id(model, uuid_key = "uuid", id_key = "id", fill = {})
      model = pop_uuid(model, @params, uuid_key, fill)
      @params[id_key] = model.id

      model
    end
  end

  module Parsers
    PARSE_IPV4 = proc do |param|
      begin
        #TODO: Change to ipaddress
        address = IPAddress::IPv4.new(param)
        raise(E::ArgumentError, 'Not an IPv4 address.') unless address.ipv4?
        address.to_i
      rescue ArgumentError
        raise(E::ArgumentError, "Could not parse IPv4 address: #{param}")
      end
    end

    PARSE_MAC = proc do |param|
      begin
        Trema::Mac.new(param).value
      rescue ArgumentError
        raise(E::ArgumentError, "Could not parse MAC address: #{param}")
      end
    end
  end
end
