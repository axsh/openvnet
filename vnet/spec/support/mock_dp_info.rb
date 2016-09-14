# -*- coding: utf-8 -*-

class MockEmptyDpInfo < Vnet::Core::DpInfo
  def initialize
  end
end

class MockDpInfo < Vnet::Core::DpInfo

  attr_reader :sent_messages
  attr_accessor :current_flows
  attr_accessor :added_flows
  attr_accessor :deleted_flows
  attr_reader :added_ovs_flows
  attr_reader :added_cookie
  attr_reader :added_tunnels
  attr_reader :deleted_tunnels

  def initialize(params)
    @sent_messages = []
    @current_flows = []
    @added_flows = []
    @deleted_flows = []
    @added_ovs_flows = []
    @added_cookie = []
    @added_tunnels = []
    @deleted_tunnels = []

    @lock = Mutex.new

    super
  end

  def create_mock_port_manager
    @port_manager = MockPortManager.new(self)
  end

  def send_message(message)
    @lock.synchronize { @sent_messages << message }
  end

  def add_flow(flow)
    @lock.synchronize {
      @current_flows << flow
      @current_flows.uniq!
      @added_flows << flow
      @added_flows.uniq!
    }
  end

  def add_flows(flows)
    @lock.synchronize {
      @current_flows += flows
      @current_flows.uniq!
      @added_flows += flows
      @added_flows.uniq!
    }
  end

  def del_cookie(cookie, cookie_mask = 0xffffffffffffffff)
    @lock.synchronize {
      @added_flows.select { |f|
        (f.to_trema_hash[:cookie] & cookie_mask) == (cookie & cookie_mask)
      }.tap { |deleted_flows|
        @current_flows -= deleted_flows
        @deleted_flows += deleted_flows
        @deleted_flows.uniq!
      }
    }
  end

  def del_flows(flows)
    @lock.synchronize {
      @deleted_flows << flows
      @deleted_flows.uniq!
    }
  end

  def add_ovs_flow(ovs_flow)
    @lock.synchronize { @added_ovs_flows << ovs_flow }
  end

  def add_tunnel(tunnel_name, params = {})
    @lock.synchronize { @added_tunnels << params.merge(tunnel_name: tunnel_name) }
  end

  def delete_tunnel(tunnel_name)
    @lock.synchronize { @deleted_tunnels << tunnel_name }
  end

end
