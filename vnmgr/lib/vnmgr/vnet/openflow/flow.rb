# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module Flow

    def self.create(table, priority, match, actions, options = {})
      trema_hash = {
        :match => self.convert_match(table, priority, match),
        :instructions => self.convert_instructions(actions, options),
      }
      trema_hash[:hard_timeout] = options[:hard_timeout] if options[:hard_timeout]
      trema_hash[:idle_timeout] = options[:idle_timeout] if options[:idle_timeout]
      trema_hash
    end

    private

    def self.convert_match(table, priority, match)
      match.merge!({ :table => table,
                     :priority => priority,
                   })

      Trema::Match.new(match)
    end

    def self.convert_instructions(actions, options)
      instructions = []

      if actions
        instructions << Trema::Instructions::ApplyAction.new(:actions => self.convert_actions(actions))
      end

      instructions
    end

    def self.convert_actions(actions, result = [])
      if actions.class == Hash
        actions.each { |key,arg| result << to_action(key, arg) }
      elsif actions.class == Array
        actions.each { |arg| self.convert_actions(arg, result) }
      else
        raise("Unknown action class: #{actions.class.name}.")
      end

      result
    end

    def self.to_action(tag, arg)
      case tag
      when :output then Trema::Actions::SendOutPort.new(arg)
      else
        raise("Unknown action type.")
      end
    end

  end

end

