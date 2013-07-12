# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  class RouteManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    
    def initialize(dp)
      @datapath = dp
      @routes = {}
      @route_links = {}
      @vifs = {}
    end

    def insert(network_map, dp_map, route_map)
      info "route_manager: route.uuid:#{route_map.uuid.inspect}"
      info "route_manager: route.route_type:#{route_map.route_type.inspect}"
      info "route_manager: route.vif:#{route_map.vif.inspect}"
      info "route_manager: route.route_link:#{route_map.route_link.inspect}"
      # info "route_manager: dp_map:#{dp_map.inspect}"

      return if @routes.has_key? route_map.uuid

      route = {
        :cookie => @datapath.switch.cookie_manager.acquire(:route),
        :vif => prepare_vif(route_map.vif),
        :route_link => prepare_link(route_map.route_link),
        :ipv4_address => route_map.ipv4_address,
        :ipv4_prefix => route_map.ipv4_prefix,
        :ipv4_mask => IPV4_BROADCAST << (32 - route_map.ipv4_prefix),
      }

      if route[:cookie].nil?
        error "route_manager: couldn't acquire flow cookie"
        return
      end

      if route[:vif].nil? || route[:route_link].nil?
        @datapath.switch.cookie_manager.release(:route, route[:cookie]) if route[:cookie]
        error "route_manager: couldn't prepare vif or route link"
        return
      end

      @routes[route_map.uuid] = route

      network_md = md_create(:network => route[:vif][:network_id])
      route_link_md = md_create(:route_link => route[:route_link][:id])
      change_network_md = md_create({ :clear_route_link => nil,
                                      :network => route[:vif][:network_id]
                                    })

      flows = []
      flows << Flow.create(TABLE_ROUTER_SRC, 40,
                           network_md.merge!({ :eth_dst => route[:vif][:mac_addr],
                                               :eth_type => 0x0800,
                                               :ipv4_src => route[:ipv4_address],
                                               :ipv4_src_mask => route[:ipv4_mask],
                                             }),
                           {},
                           route_link_md.merge({ :cookie => route[:cookie],
                                                 :goto_table => TABLE_ROUTER_DST
                                               }))
      flows << Flow.create(TABLE_ROUTER_DST, 40,
                           route_link_md.merge!({ :eth_type => 0x0800,
                                                  :ipv4_dst => route[:ipv4_address],
                                                  :ipv4_dst_mask => route[:ipv4_mask],
                                                }),
                           { :eth_src => route[:vif][:mac_addr] },
                           change_network_md.merge({ :cookie => route[:cookie],
                                                     :goto_table => TABLE_ROUTER_EXIT
                                                   }))

      @datapath.add_flows(flows)
    end

    def prepare_network(network_map, dp_map)
      network_map.batch.routes.commit(:fill => [:route_link, :vif]).each { |route|
        self.insert(network_map, dp_map, route)
      }
    end

    private

    def prepare_link(link_map)
      link = @route_links[link_map.id]
      return link if link

      link = {
        :id => link_map.id,
      }

      @route_links[link_map.id] = link

      return link
    end

    def prepare_vif(vif_map)
      vif = @vifs[vif_map.id]
      return vif if vif

      vif = {
        :cookie => @datapath.switch.cookie_manager.acquire(:route),
        :network_id => vif_map.network_id,
        :mac_addr => Trema::Mac.new(vif_map.mac_addr),
      }

      if vif[:cookie].nil?
        error "route_manager: couldn't acquire flow cookie"
        return nil
      end

      @vifs[vif_map.id] = vif

      flows = []
      flows << Flow.create(TABLE_ROUTER_ENTRY, 40,
                           md_create(:network => vif[:network_id]).merge!(:eth_dst => vif[:mac_addr]), {
                           }, {
                             :cookie => vif[:cookie],
                             :goto_table => TABLE_ROUTER_SRC
                           })

      @datapath.add_flows(flows)

      return vif
    end

  end

end
