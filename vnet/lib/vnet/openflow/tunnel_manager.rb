# -*- coding: utf-8 -*-

module Vnet::Openflow

  class TunnelManager < Manager

    def initialize(dp_info)
      super

      @datapath = dp_info.datapath

      @tunnel_ports = {}
    end

    def tunnels_dup
      @items.dup
    end

    def create_all_tunnels
      debug "creating tunnel ports"

      if @datapath_info.nil?
        error log_format('datapath information not loaded')
        return nil
      end

      MW::Datapath.batch[@datapath_info.id].on_other_segments.commit.each { |target_dp_map|
        tunnel_name = "t-#{target_dp_map.uuid.split("-")[1]}"
        tunnel = MW::Tunnel.create(src_datapath_id: @datapath_info.id,
                                   dst_datapath_id: target_dp_map.id,
                                   display_name: tunnel_name)

        @items[tunnel.id] = tunnel.to_hash.tap { |t|
          t[:dst_dpid] = target_dp_map.dpid
          t[:datapath_networks] = []
          t[:dst_ipv4_address] = target_dp_map.ipv4_address
        }
      }

      @items.each { |tunnel_id, tunnel|
        @datapath.add_tunnel(tunnel[:display_name], IPAddr.new(tunnel[:dst_ipv4_address], Socket::AF_INET).to_s)
      }
    end

    def insert(dpn_map, should_update = false)
      datapath_network = {
        :id => dpn_map.id,
        :dpid => dpn_map.datapath.dpid,
        :ipv4_address => dpn_map.datapath.ipv4_address,
        :datapath_id => dpn_map.datapath.dpid,
        :broadcast_mac_address => Trema::Mac.new(dpn_map.broadcast_mac_address),
        :network_id => dpn_map.network_id,
      }

      tunnel = @items.detect { |tunnel_id, tunnel|
        tunnel[:dst_dpid] == datapath_network[:dpid]
      }
      tunnel[1][:datapath_networks] << datapath_network if tunnel

      update_network_id(datapath_network[:network_id]) if should_update
    end

    def add_port(port)
      old_port = @tunnel_ports.delete(port.port_number)

      if old_port
        error "tunnel_manager: port already added (port:#{port.port_number} old:#{old_port[:port_name]} new:#{port.port_name})"
      end

      @tunnel_ports[port.port_number] = {
        :port_name => port.port_name,
      }

      update_tunnel(port.port_number)
    end

    def del_port(port)
      old_port = @tunnel_ports.delete(port.port_number)

      update_tunnel(old_port[:port_name]) if old_port
    end

    def prepare_network(network_map, dp_map)
      update_networks = false

      network_map.batch.datapath_networks_dataset.on_other_segment(dp_map).all.commit(:fill => :datapath).each { |dpn|
        self.insert(dpn, false)

        # Only add non-existing ones...
        update_networks = true
      }

      update_network_id(network_map.id) if update_networks
    end

    def update_network_id(network_id)
      collection_id = find_collection_id(network_id)

      cookie = network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)
      md = md_create(:collection => collection_id)

      flows = []
      flows << Flow.create(TABLE_FLOOD_TUNNEL_IDS, 1,
                           md_create(:network => network_id), {
                             :tunnel_id => network_id | TUNNEL_FLAG_MASK
                           }, md.merge({ :cookie => cookie,
                                         :goto_table => TABLE_FLOOD_TUNNEL_PORTS
                                       }))

      @datapath.add_flows(flows)
    end

    def delete_tunnel_port(network_id, remote_dpid)

      # if #{remote_dpid} is equal to #{@datapath.dpid},
      # it can be regard as the network deletion happens on
      # the local datapath (not on the remote datapath)

      if remote_dpid == @datapath.dpid
        debug "delete tunnel on local datapath: local_dpid => #{@datapath.dpid} remote_dpid => #{remote_dpid}"
        @items.each do |tunnel_id, tunnel|
          debug "try to delete tunnel #{t[:display_name]}"
          delete_tunnel_if_datapath_networks_empty(t, network_id)
        end
      else
        debug "delete tunnel for remote datapath: local_dpid => #{@datapath.dpid} remote_dpid => #{remote_dpid}"
        @items.each do |tunnel_id, tunnel|
          if t[:dst_dpid] == "0x%016x" % remote_dpid
            debug "found a tunnel to delete: display_name => #{t[:display_name]}"
            delete_tunnel_if_datapath_networks_empty(t, network_id)
          end
        end
      end

      @items.delete_if { |tunnel_id, tunnel| tunnel[:datapath_networks].empty? }
    end

    private

    def update_tunnel(port_number)
      port = @tunnel_ports[port_number]

      if port.nil?
        warn "tunnel_manager: port number not found (#{port_number})"
        return
      end

      tunnel = @items.detect { |tunnel_id, tunnel| tunnel[:display_name] == port[:port_name] }

      if tunnel.nil?
        warn "tunnel_manager: port name is not registered in database (#{port[:port_name]})"
        return
      end

      datapath_md = md_create(datapath: tunnel[1][:dst_datapath_id],
                              tunnel: nil)
      cookie = tunnel[1][:dst_datapath_id] | (COOKIE_PREFIX_COLLECTION << COOKIE_PREFIX_SHIFT)

      flow = Flow.create(TABLE_OUTPUT_DATAPATH, 5,
                         datapath_md, {
                           :output => port_number
                         }, {
                           :cookie => cookie
                         })

      @datapath.add_flow(flow)

      tunnel[1][:datapath_networks].each { |dpn|
        update_network_id(dpn[:network_id])
      }
    end

    def find_collection_id(network_id)
      # Currently only use the network id as the collection id.
      #
      # Later collections should be created as needed and shared
      # between network's when possible.
      update_collection_id(network_id)

      network_id
    end

    def update_collection_id(collection_id)
      ports = @tunnel_ports.select { |port_number,tunnel_port|
        tunnel = @items.find{ |tunnel_id, tunnel| tunnel[:display_name] == tunnel_port[:port_name] }

        if tunnel.nil?
          warn "tunnel port: #{tunnel_port[:port_name]} is not registered in db"
          next
        end

        tunnel[1][:datapath_networks].any? { |dpn| dpn[:network_id] == collection_id }
      }

      collection_md = md_create(:collection => collection_id)
      cookie = collection_id | (COOKIE_PREFIX_COLLECTION << COOKIE_PREFIX_SHIFT)

      flows = []
      flows << Flow.create(TABLE_FLOOD_TUNNEL_PORTS, 1,
                           collection_md,
                           ports.map { |port_number, port|
                             {:output => port_number}
                           }, {
                             :cookie => cookie
                           })

      @datapath.add_flows(flows)
    end

    def delete_tunnel_if_datapath_networks_empty(tunnel, network_id)
      tunnel[:datapath_networks].delete_if { |dpn| dpn[:network_id] == network_id }
      if tunnel[:datapath_networks].empty?
        debug "delete tunnel #{tunnel[:display_name]}"
        @datapath.delete_tunnel(tunnel[:display_name])
        t = MW::Tunnel[:display_name => tunnel[:display_name]]
        t.batch.destroy.commit
      else
        debug "tunnel datapath is not empty"
      end
    end
  end
end
