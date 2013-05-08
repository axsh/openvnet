# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class Flow
    attr_accessor :table
    attr_accessor :priority
    attr_accessor :match
    attr_accessor :actions
    attr_accessor :options

    def initialize table, priority, match, actions, options = nil
      super()
      self.table = table
      self.priority = priority
      self.match = match
      self.actions = actions
      self.options = options
    end

    def to_trema_flow
      trema_hash = {:match => self.match_to_trema, :instructions => self.actions_to_trema}
      trema_hash[:hard_timeout] = options[:hard_timeout] if options[:hard_timeout]
      trema_hash[:idle_timeout] = options[:idle_timeout] if options[:idle_timeout]
      trema_hash
    end

    def match_to_s
      str = "table=#{table},priority=#{priority}"

      self.match.each { |key,value|
        tag = match_tags_ovs[key]
        raise "No match tag: key:'#{key.inspect}'." if tag.nil?

        str << "," << tag % value
      }
      str
    end

    def match_sparse_to_s
      str = "table=#{table}"

      self.match.each { |key,value|
        tag = match_tags_ovs[key]
        raise "No match tag: key:'#{key.inspect}'." if tag.nil?

        str << "," << tag % value
      }
      str
    end

    def match_to_trema
      trema_hash = {
        :table => table,
        :priority => priority,
      }

      self.match.each { |key,value|
        tag = match_tags_trema[key]
        raise "No match tag: key:'#{key.inspect}'." if tag.nil?

        trema_hash[tag] = value
      }

      Trema::Match.new(trema_hash)
    end

    # Note; the Hash objects before ruby 1.9 do not maintain order
    # of insertion when iterating, so the actions will be reordered.
    #
    # As the action list is order-sensetive the action list won't
    # be strictly correct in earlier versions of ruby, however we
    # don't currently use any such flows.
    def actions_to_s
      if actions.class == Array
        str = ""
        self.actions.each { |block|
          str << actions_block_to_s(block)
        }
        str
      else
        actions_block_to_s actions
      end
    end

    def actions_block_to_s block, args = nil
      str = ""

      block.each { |key,value|
        if key == :for_each || key == :for_each2
          value[0].each { |arg|
            str << actions_block_to_s(value[1], arg)
          }
        else
          tag = action_tags_ovs[key]
          raise "No action tag: key:#{key.inspect}" if tag.nil?

          case value
          when :placeholder
            str << ',' << tag % args
          else
            str << ',' << tag % value
          end
        end
      }

      str
    end

    def actions_to_trema
      actions_block_to_trema(self.actions)
    end

    def actions_block_to_trema block, args = nil
      trema_instructions = []
      trema_actions = nil

      block.each { |key,value|
        if key == :for_each || key == :for_each2
          value[0].each { |arg|
            # str << actions_block_to_s(value[1], arg)
          }
        #elsif action_tags_trema_instruction(key)
          # Make a new instruction, not append to action instruction.
        else
          tag = action_tags_trema[key]
          raise "No action tag: key:#{key.inspect}" if tag.nil?

          trema_actions = [] if trema_actions.nil?

          case value
          when :placeholder
            trema_actions << (args.nil? ? tag.new : tag.new(args))
          else
            trema_actions << (value.nil? ? tag.new : tag.new(value))
          end
        end
      }

      trema_instructions << Trema::Instructions::ApplyAction.new(:actions => trema_actions) if trema_actions
      trema_instructions
    end

    def match_tags_ovs
      {
        :ip => 'ip',
        :ipv4 => 'ip',
        :ipv6 => 'ipv6',
        :arp => 'arp',
        :icmp => 'icmp',
        :icmp_type => 'icmp_type=%i',
        :icmp_code => 'icmp_code=%i',
        :tcp => 'tcp',
        :udp => 'udp',
        :dl_dst => 'dl_dst=%s',
        :dl_src => 'dl_src=%s',
        :dl_type => 'dl_type=0x%x',
        :nw_dst => 'nw_dst=%s',
        :nw_src => 'nw_src=%s',
        :nw_proto => 'nw_proto=%i',
        :tp_dst => 'tp_dst=%s',
        :tp_src => 'tp_src=%s',
        :arp_sha => 'arp_sha=%s',
        :arp_tha => 'arp_tha=%s',
        :in_port => 'in_port=%i',
        :reg1 => 'reg1=%i',
        :reg2 => 'reg2=%i',

        # Not really match tags, separate.
        :idle_timeout => 'idle_timeout=%i',
      }
    end

    def action_tags_ovs
      {
        :controller => 'controller',
        :drop => 'drop',
        :learn => 'learn(%s)',
        :local => 'local',
        :load_reg0 => 'load:%i->NXM_NX_REG0[]',
        :load_reg1 => 'load:%i->NXM_NX_REG1[]',
        :load_reg2 => 'load:%i->NXM_NX_REG2[]',
        :mod_dl_dst => 'mod_dl_dst:%s',
        :mod_dl_src => 'mod_dl_src:%s',
        :mod_nw_dst => 'mod_nw_dst:%s',
        :mod_nw_src => 'mod_nw_src:%s',
        :mod_tp_dst => 'mod_tp_dst:%i',
        :mod_tp_src => 'mod_tp_src:%i',
        :normal => 'normal',
        :output => 'output:%i',
        :output_reg0 => 'output:NXM_NX_REG0[]',
        :output_reg1 => 'output:NXM_NX_REG1[]',
        :output_reg2 => 'output:NXM_NX_REG2[]',
        :resubmit => 'resubmit(,%i)',
      }
    end

    def match_tags_trema
      {
        :ip => :ip,
        :ipv4 => :ip,
        # :ipv6 => 'ipv6',
        # :arp => 'arp',
        # :icmp => 'icmp',
        # :icmp_type => 'icmp_type=%i',
        # :icmp_code => 'icmp_code=%i',
        # :tcp => 'tcp',
        # :udp => 'udp',
        # :dl_dst => 'dl_dst=%s',
        # :dl_src => 'dl_src=%s',
        # :dl_type => 'dl_type=0x%x',
        :eth_dst => :eth_dst,
        :eth_src => :eth_src,
        :eth_type => :eth_type,
        # :nw_dst => 'nw_dst=%s',
        # :nw_src => 'nw_src=%s',
        # :nw_proto => 'nw_proto=%i',
        # :tp_dst => 'tp_dst=%s',
        # :tp_src => 'tp_src=%s',
        # :arp_sha => 'arp_sha=%s',
        # :arp_tha => 'arp_tha=%s',
        # :in_port => 'in_port=%i',
        # :reg1 => 'reg1=%i',
        # :reg2 => 'reg2=%i',

        # Not really match tags, separate.
        # :idle_timeout => 'idle_timeout=%i',
      }
    end

    def action_tags_trema
      {
        # :controller => 'controller',
        # :drop => 'drop',
        # :learn => 'learn(%s)',
        # :local => 'local',
        # :load_reg0 => 'load:%i->NXM_NX_REG0[]',
        # :load_reg1 => 'load:%i->NXM_NX_REG1[]',
        # :load_reg2 => 'load:%i->NXM_NX_REG2[]',
        # :mod_dl_dst => 'mod_dl_dst:%s',
        # :mod_dl_src => 'mod_dl_src:%s',
        # :mod_nw_dst => 'mod_nw_dst:%s',
        # :mod_nw_src => 'mod_nw_src:%s',
        # :mod_tp_dst => 'mod_tp_dst:%i',
        # :mod_tp_src => 'mod_tp_src:%i',
        # :normal => 'normal',
        :output => Trema::Actions::SendOutPort,
        # :output_reg0 => 'output:NXM_NX_REG0[]',
        # :output_reg1 => 'output:NXM_NX_REG1[]',
        # :output_reg2 => 'output:NXM_NX_REG2[]',
        # :resubmit => 'resubmit(,%i)',
      }
    end
  end

end

