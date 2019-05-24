# -*- coding: utf-8 -*-

module Vnet::Openflow
  module FlowHelpers
    include MetadataHelpers

    Flow = Vnet::Openflow::Flow

    FLOW_MATCH_METADATA_PARAMS = [:match_reflection,
                                  :match_remote,
                                  :match_first,
                                  :match_second,
                                 ]
    FLOW_WRITE_METADATA_PARAMS = [:write_reflection,
                                  :write_remote,
                                  :write_first,
                                  :write_second,
                                 ]

    def is_address_ipv4?(address)
      case address
      when nil
        return false
      when Pio::IPv4Address
        return address.value.ipv4?
      when IPAddr
        return address.ipv4?
      when String
        begin
          IPAddr.new(addr, Socket::AF_INET)
        rescue IPAddr::InvalidAddressError
          return false
        end
        return true
      else
        raise "Unknown address type '#{address.inspect}."
      end
    end

    def is_ipv4_broadcast(address, prefix)
      address == IPV4_ZERO && prefix == 0
    end

    def match_ipv4_subnet_dst(address, prefix)
      if is_ipv4_broadcast(address, prefix)
        { ether_type: ETH_TYPE_IPV4 }
      else
        { ether_type: ETH_TYPE_IPV4,
          ipv4_destination_address: Pio::IPv4Address.new(address),
          ipv4_destination_address_mask: IPV4_BROADCAST.mask(prefix),
        }
      end
    end

    def match_ipv4_subnet_src(address, prefix)
      if is_ipv4_broadcast(address, prefix)
        { ether_type: ETH_TYPE_IPV4 }
      else
        { ether_type: ETH_TYPE_IPV4,
          ipv4_source_address: Pio::IPv4Address.new(address),
          ipv4_source_address_mask: IPV4_BROADCAST.mask(prefix),
        }
      end
    end

    def flow_create(params)
      match_metadata = {}
      write_metadata = {}

      #
      # Match/Write Metadata options:
      #
      FLOW_MATCH_METADATA_PARAMS.each { |type|
        match_metadata[type] = params[type] if params.has_key? type
      }
      FLOW_WRITE_METADATA_PARAMS.each { |type|
        write_metadata[type] = params[type] if params.has_key? type
      }

      #
      # Output:
      #
      match_metadata = match_metadata.merge!(params[:match_metadata]) if params[:match_metadata]
      write_metadata = write_metadata.merge!(params[:write_metadata]) if params[:write_metadata]

      match = {}
      match = match.merge!(params[:match]) if params[:match]
      match = match.merge!(md_create(match_metadata)) if !match_metadata.empty?

      instructions = {}
      instructions[:cookie] = params[:cookie] || self.cookie
      instructions[:goto_table] = params[:goto_table] if params[:goto_table]

      instructions[:hard_timeout] = params[:hard_timeout] if params[:hard_timeout]
      instructions[:idle_timeout] = params[:idle_timeout] if params[:idle_timeout]

      instructions.merge!(md_create(write_metadata)) if !write_metadata.empty?

      raise "Missing cookie." if instructions[:cookie].nil?

      Flow.create(params[:table],
                  params[:priority],
                  match,
                  params[:actions],
                  instructions)
    end

    def flows_for_filtering_mac_address(flows, mac_address, use_cookie = self.cookie)
      [[TABLE_SEGMENT_SRC_CLASSIFIER_SEG_NIL, { source_mac_address: mac_address }],
       [TABLE_SEGMENT_SRC_CLASSIFIER_SEG_NIL, { destination_mac_address: mac_address }],
       [TABLE_SEGMENT_DST_CLASSIFIER_SEG_NW, { source_mac_address: mac_address }],
       [TABLE_SEGMENT_DST_CLASSIFIER_SEG_NW, { destination_mac_address: mac_address }],
       [TABLE_NETWORK_SRC_CLASSIFIER_NW_NIL, { source_mac_address: mac_address }],
       [TABLE_NETWORK_SRC_CLASSIFIER_NW_NIL, { destination_mac_address: mac_address }],
       [TABLE_NETWORK_DST_CLASSIFIER_NW_NIL, { source_mac_address: mac_address }],
       [TABLE_NETWORK_DST_CLASSIFIER_NW_NIL, { destination_mac_address: mac_address }],
      ].each { |table, match|
        flows << flow_create(table: table,
                             priority: 90,
                             match: match,
                             cookie: use_cookie)
      }
    end

  end
end
