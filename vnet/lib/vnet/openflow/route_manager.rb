# -*- coding: utf-8 -*-

module Vnet::Openflow

  class RouteManager < Manager

    ROUTE_COMMIT = {:fill => [:route_link]}

    def initialize(dp_info)
      super

      @route_links = {}
      @interfaces = {}
    end

    #
    # Refactor:
    #

    def insert(route_map)
      route_link = prepare_link(route_map.route_link)

      return if route_link.nil?
      return if route_link.routes.has_key? route_map.id

      info log_format("insert #{route_map.uuid}/#{route_map.id}", "interface_id:#{route_map.interface_id}")

      route = Routes::Base.new(dp_info: @dp_info,
                               manager: self,
                               map: route_map)

      @items[route.id] = route

      route_link.routes[route.id] = route

      interface = prepare_interface(route_map.interface_id)

      if interface.nil?
        warn log_format('couldn\'t prepare router interface', "#{route_map.uuid}")
        return
      end

      route.network_id = interface[:network_id]
      route.use_datapath_id = interface[:use_datapath_id]
      route.install
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

      route_link = Routers::RouteLink.new(dp_info: @dp_info, map: rl_map)

      cookie = route_link.id | COOKIE_TYPE_ROUTE_LINK

      @route_links[route_link.id] = route_link

      tunnel_md = md_create(:tunnel => nil)
      route_link_md = md_create(:route_link => route_link.id)

      # TODO: Move flow creation to Routers::RouteLink...

      flows = []
      flows << Flow.create(TABLE_TUNNEL_NETWORK_IDS, 30, {
                             :tunnel_id => TUNNEL_ROUTE_LINK,
                             :eth_dst => route_link.mac_address
                           }, nil,
                           route_link_md.merge({ :cookie => cookie,
                                                 :goto_table => TABLE_ROUTE_LINK_EGRESS
                                               }))
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                             :eth_dst => route_link.mac_address
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 90, {
                             :eth_src => route_link.mac_address
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                             :eth_dst => route_link.mac_address
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 90, {
                             :eth_src => route_link.mac_address
                           }, nil, {
                             :cookie => cookie
                           })
      flows << Flow.create(TABLE_OUTPUT_ROUTE_LINK, 4, {
                             :eth_dst => route_link.mac_address
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
                             datapath_md.merge(:eth_dst => route_link.mac_address), {
                               :eth_dst => Trema::Mac.new(dp_rl_map.mac_address)
                             }, mac2mac_md.merge({ :goto_table => TABLE_OUTPUT_ROUTE_LINK_HACK,
                                                   :cookie => cookie
                                                 }))
      }

      # ROUTER_DST catch unknown subnets. ??? (or load all subnets)

      @dp_info.add_flows(flows)
      route_link
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

  end

end
