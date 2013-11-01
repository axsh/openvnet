# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Manager

    ROUTE_COMMIT = {:fill => [:route_link]}

    def initialize(dp_info)
      super

      @route_links = {}
      @interfaces = {}
    end

    def packet_in(message)
      case message.cookie >> COOKIE_PREFIX_SHIFT
      when COOKIE_PREFIX_ROUTE
        item = @items[message.cookie & COOKIE_ID_MASK]
        item[:route_link][:packet_handler].packet_in(message) if item
      when COOKIE_PREFIX_ROUTE_LINK
        route_link = @route_links[message.cookie & COOKIE_ID_MASK]
        route_link.packet_in(message) if route_link
      end

      nil
    end

    #
    # Refactor:
    #

    def insert(route_map)
      route_link = prepare_link(route_map.route_link)

      return if route_link.nil?
      return if route_link[:routes].has_key? route_map.id

      info log_format("insert #{route_map.uuid}/#{route_map.id}", "interface_id:#{route_map.interface_id}")
      # info log_format('insert', "route.route_type:#{route_map.route_type}")
      # info log_format('insert', "route.route_link: id:#{route_map.route_link.id} uuid:#{route_map.route_link.uuid}")

      route = {
        :id => route_map.id,
        :uuid => route_map.uuid,
        :interface => nil,
        :ipv4_address => IPAddr.new(route_map.ipv4_network, Socket::AF_INET),
        :ipv4_prefix => route_map.ipv4_prefix,
        :ingress => route_map.ingress,
        :egress => route_map.egress,

        :route_link => route_link
      }

      @items[route[:id]] = route
      route_link[:routes][route[:id]] = route

      route[:interface] = prepare_interface(route_map.interface_id)

      if route[:interface].nil?
        warn log_format('couldn\'t prepare router interface', "#{route_map.uuid}")
        return
      end

      create_route_flows(route_link, route)
    end

    def prepare_network(network_map, dp_map)
      network_map.batch.routes.commit(ROUTE_COMMIT).each { |route_map|
        if !@route_links.has_key?(route_map.route_link.id)
          route_map.batch.on_other_networks(network_map.id).commit(ROUTE_COMMIT).each { |other_route_map|
            # Replace with a lightweight methods.
            self.insert(other_route_map)
          }
        end

        self.insert(route_map)
      }
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} route_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #


    #
    # Refactor:
    #

    def datapath_route_link(rl_map)
      @datapath_info.datapath_map.batch.datapath_route_links_dataset.where(:route_link_id => rl_map.id).all.commit
    end

    def dp_rl_on_segment(rl_map)
      rl_map.batch.datapath_route_links_dataset.on_segment(@datapath_info.datapath_map).all.commit
    end

    def prepare_link(rl_map)
      link = @route_links[rl_map.id]
      return link if link

      mac_address = Trema::Mac.new(rl_map.mac_address)
      packet_handler = Routers::RouteLink.new(dp_info: @dp_info,
                                              route_link_id: rl_map.id,
                                              route_link_uuid: rl_map.uuid,
                                              mac_address: mac_address)

      link = {
        :id => rl_map.id,
        :uuid => rl_map.uuid,
        :mac_address => mac_address,
        :routes => {},
        :packet_handler => packet_handler
      }

      cookie = link[:id] | COOKIE_TYPE_ROUTE_LINK

      @route_links[rl_map.id] = link

      tunnel_md = md_create(:tunnel => nil)
      route_link_md = md_create(:route_link => link[:id])

      # TODO: Move flow creation to Routers::RouteLink...

      flows = []
      flows << Flow.create(TABLE_TUNNEL_NETWORK_IDS, 30, {
                             :tunnel_id => TUNNEL_ROUTE_LINK,
                             :eth_dst => link[:mac_address]
                           }, nil,
                           route_link_md.merge({ :cookie => cookie,
                                                 :goto_table => TABLE_ROUTE_LINK_EGRESS
                                               }))
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                             :eth_dst => link[:mac_address]
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                             :eth_src => link[:mac_address]
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                             :eth_dst => link[:mac_address]
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                             :eth_src => link[:mac_address]
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_OUTPUT_ROUTE_LINK, 4, {
                             :eth_dst => mac_address
                           }, {
                             :tunnel_id => TUNNEL_ROUTE_LINK
                           }, tunnel_md.merge({ :goto_table => TABLE_OUTPUT_ROUTE_LINK_HACK,
                                                :cookie => cookie
                                              }))

      # Handle MAC2MAC packets for this route link using a unique MAC
      # address for this datapath, route link pair.
      datapath_route_link(rl_map).each { |dp_rl_map|
        flows << Flow.create(TABLE_HOST_PORTS, 30, {
                               :eth_dst => Trema::Mac.new(dp_rl_map.mac_address)
                             }, nil,
                             route_link_md.merge({ :cookie => cookie,
                                                   :goto_table => TABLE_ROUTE_LINK_EGRESS
                                                 }))
        flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                               :eth_dst => Trema::Mac.new(dp_rl_map.mac_address)
                             }, nil, {
                               :cookie => cookie
                             })
        flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                               :eth_dst => Trema::Mac.new(dp_rl_map.mac_address)
                             }, nil, {
                               :cookie => cookie
                             })
      }

      # Use the datapath id in the metadata field and the route link
      # MAC address in the destination field to figure out the MAC2MAC
      # datapath, route link pair MAC address to use.
      #
      # If not found it is assumed to be using a tunnel where the
      # route link MAC address is to be used.
      dp_rl_on_segment(rl_map).each { |dp_rl_map|
        datapath_md = md_create(:datapath => dp_rl_map.datapath_id)
        mac2mac_md = md_create(:mac2mac => nil)

        flows << Flow.create(TABLE_OUTPUT_ROUTE_LINK, 5,
                             datapath_md.merge(:eth_dst => mac_address), {
                               :eth_dst => Trema::Mac.new(dp_rl_map.mac_address)
                             }, mac2mac_md.merge({ :goto_table => TABLE_OUTPUT_ROUTE_LINK_HACK,
                                                   :cookie => cookie
                                                 }))
      }

      # ROUTER_DST catch unknown subnets. ??? (or load all subnets)

      @dp_info.add_flows(flows)
      link
    end

    def prepare_interface(interface_id)
      interface_item = @dp_info.interface_manager.item(id: interface_id)
      return nil if interface_item.nil?

      info log_format('from interface_manager' , "#{interface_item.uuid}/#{interface_id}")

      interface = interface_item && @interfaces[interface_item.id]
      return interface if interface

      if interface_item.mode != :simulated && interface_item.mode != :remote
        info log_format('only interfaces with mode \'simulated\' are supported', "uuid:#{interface_item.uuid} mode:#{interface_item.mode}")
        return
      end

      mac_info = interface_item.mac_addresses.first

      if mac_info.nil? ||
          mac_info[1][:ipv4_addresses].first.nil?
        warn log_format('could not find ipv4 address')
        return nil
      end

      ipv4_info = mac_info[1][:ipv4_addresses].first

      interface = {
        :id => interface_item.id,
        :use_datapath_id => nil,

        :mac_address => mac_info[1][:mac_address],
        :mode => interface_item.mode,

        :network_id => ipv4_info[:network_id],
        :ipv4_address => ipv4_info[:ipv4_address],
      }

      case ipv4_info[:network_type]
      when :physical
        interface[:require_interface] = false
      when :virtual
        interface[:require_interface] = true
      else
        warn log_format('interface does not have a known network type', "#{interface_item.uuid}")
        return nil
      end

      @interfaces[interface_item.id] = interface

      if interface_item.mode == :remote
        interface[:use_datapath_id] = interface_item.owner_datapath_ids && interface_item.owner_datapath_ids.first

        return interface
      end

      datapath_id = @datapath_info.datapath_map.id

      # Fix this...
      if interface_item.owner_datapath_ids
        if interface_item.owner_datapath_ids.include? datapath_id
          @dp_info.interface_manager.update_item(event: :active_datapath_id,
                                                 id: interface_item.id,
                                                 datapath_id: datapath_id)
        else
          interface[:use_datapath_id] = interface_item.owner_datapath_ids.first
        end
      end

      if interface[:use_datapath_id].nil?
        @dp_info.interface_manager.async.update_item(event: :enable_router_ingress,
                                                     id: interface[:id])
      end

      interface
    end

    def create_route_flows(route_link, route)
      cookie = route[:id] | COOKIE_TYPE_ROUTE

      flows = []

      subnet_dst = match_ipv4_subnet_dst(route[:ipv4_address], route[:ipv4_prefix])
      subnet_src = match_ipv4_subnet_src(route[:ipv4_address], route[:ipv4_prefix])

      if route[:interface][:use_datapath_id].nil?
        flows << flow_create(:routing,
                             table: TABLE_INTERFACE_EGRESS_ROUTES,
                             goto_table: TABLE_INTERFACE_EGRESS_MAC,

                             match: subnet_dst,
                             match_interface: route[:interface][:id],
                             write_network: route[:interface][:network_id],
                             default_route: is_ipv4_broadcast(route[:ipv4_address], route[:ipv4_prefix]),
                             cookie: cookie)

        if route[:ingress] == true
          flows << flow_create(:routing,
                               table: TABLE_ROUTE_LINK_INGRESS,
                               goto_table: TABLE_ROUTE_LINK_EGRESS,

                               match: subnet_src,
                               match_interface: route[:interface][:id],
                               write_route_link: route_link[:id],
                               default_route: is_ipv4_broadcast(route[:ipv4_address], route[:ipv4_prefix]),
                               write_reflection: true,
                               cookie: cookie)
        end

        if route[:egress] == true
          flows << flow_create(:routing,
                               table: TABLE_ROUTE_LINK_EGRESS,
                               goto_table: TABLE_ROUTE_EGRESS,

                               match: subnet_dst,
                               match_route_link: route_link[:id],
                               write_interface: route[:interface][:id],
                               default_route: is_ipv4_broadcast(route[:ipv4_address], route[:ipv4_prefix]),
                               cookie: cookie)

          route_link[:packet_handler].insert_route(route)
        end

        @dp_info.add_flows(flows)

      else
        if route[:egress] == true
          flows << flow_create(:routing,
                               table: TABLE_ROUTE_LINK_EGRESS,
                               goto_table: TABLE_OUTPUT_ROUTE_LINK,

                               match: subnet_dst,
                               match_route_link: route_link[:id],
                               write_datapath: route[:interface][:use_datapath_id],
                               default_route: is_ipv4_broadcast(route[:ipv4_address], route[:ipv4_prefix]),
                               cookie: cookie)
        end

        @dp_info.add_flows(flows)
      end
    end

  end

end
