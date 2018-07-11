module Vnspec
  module Models
    module BaseModule
      def initialize(options)
        super
        @uuid = options[:uuid]
      end
    end

    class Base
      attr_reader :uuid

      class << self
        def inherited(klass)
          klass.class_eval do
            prepend(BaseModule)
            def self.inherited(klass)
              klass.class_eval do
                prepend(BaseModule)
              end
            end
          end
        end

        def all(options = {})
          @items ||= []
          if @items.empty? || options[:reload]
            API.request(:get, api_name, limit: 1000) do |response|
              @items = response[:items].map do |r|
                item = self.new(r)
                # TODO associations
              end
            end
          end
          @items
        end

        def find(id, options = {})
          case id
          when String
            all(options).find { |i| i.uuid == id }
          when Integer
            all(options).find { |i| i.id == id }
          when Hash
            all(options).find do |i|
              options.all? do |k, v|
                i.__send__(k) == v
              end
            end
          end
        end
        alias_method :[], :find

        def reload(id = nil)
          options = { reload: true }
          if id
            find(id, options)
          else
            all(options)
          end
        end

        def create(options)
          API.request(:post, api_name, options) do |response|
            return reload(response[:uuid])
          end
        end

        def post(options)
          API.request(:post, api_name, options)
        end

        def put(options)
          API.request(:put, api_name, options)
        end
      end

      def ==(other)
        self.uuid == other.uuid
      end

      def api_name
        self.class.api_name
      end

      def reload
        self.class.reload(self.uuid)
      end
    end

    class Interface < Base
      attr_reader :mac_leases

      class << self
        def api_name
          "interfaces"
        end

        def all(options = {})
          @items ||= []
          if @items.empty? || options[:reload]
            API.request(:get, api_name, limit: 1000) do |response|
              @items = response[:items].map do |r|
                self.new(r).tap do |interface|
                  r[:mac_leases].each do |m|
                    interface.mac_leases << Models::MacLease.new(uuid: m[:uuid], interface: interface,  mac_address: m[:mac_address]).tap do |mac_lease|
                      m[:ip_leases].each do |i|
                        mac_lease.ip_leases << Models::IpLease.new(uuid: i[:uuid], mac_lease: mac_lease, ipv4_address: i[:ipv4_address], network_uuid: i[:network_uuid])
                      end
                    end
                  end
                end
              end
            end
          end
          @items
        end
      end

      def initialize(options)
        @mac_leases = []
      end

      def update(options)
        API.request(:put, "interfaces/#{uuid}", options) do |response|
          @display_name = response[:display_name]
          @owner_datapath_uuid = response[:owner_datapath_uuid]
        end
        reload
      end

      def update_host_interface(datapath_uuid, port_name)
        options = {
          datapath_uuid: datapath_uuid,
          singular: true,
          port_name: port_name
        }

        API.request(:post, "interfaces/#{uuid}/ports", options) do |response|
          @owner_datapath_uuid = datapath_uuid
        end
        reload
      end

      def destroy
        API.request(:delete, "interfaces/#{uuid}")
        reload
      end

      def mac_lease(uuid)
        self.mac_leases.find{|m| m.uuid == uuid}
      end

      def add_mac_lease(options)
        MacLease.create(self, options).tap do |mac_lease|
          self.mac_leases << mac_lease
        end
      end

      def remove_mac_lease(uuid)
        mac_leases(uuid).tap(&:destroy)
      end

      def add_security_group(uuid)
        Vnspec::API.request(:post, "interfaces/#{@uuid}/security_groups/#{uuid}")
      end

      def remove_security_group(uuid)
        Vnspec::API.request(:delete, "interfaces/#{@uuid}/security_groups/#{uuid}")
      end

      def enabled?
        !! @enabled
      end
    end

    class MacLease < Base
      attr_reader :interface
      attr_reader :mac_address
      attr_reader :ip_leases
      attr_reader :segment_uuid

      class << self
        def api_name
          "mac_leases"
        end

        def create(interface, options)
          super(options.merge(interface_uuid: interface.uuid))
        end
      end

      def initialize(options)
        @interface = options[:interface]
        @mac_address = options[:mac_address]
        @segment_uuid = options[:segment_uuid] # TODO
        @ip_leases = []
      end

      def destroy
        API.request(:delete, "mac_leases/#{uuid}")
        self.interface.mac_leases.delete_if{|m| m.uuid == uuid}
        reload
      end

      def add_ip_lease(options)
        self.ip_leases << IpLease.create(self, options)
      end

      def remove_ip_lease(uuid)
        ip_leases(uuid).destroy
      end
    end

    class IpLease < Base
      attr_reader :mac_lease
      attr_reader :ipv4_address
      attr_reader :network_uuid

      class << self
        def api_name
          "ip_leases"
        end

        def create(mac_lease, options)
          super(options.merge(mac_lease_uuid: mac_lease.uuid))
        end
      end

      def initialize(options)
        @mac_lease = options[:mac_lease]
        @ipv4_address = options[:ipv4_address]
        @network_uuid = options[:network_uuid] # TODO
      end

      def destroy
        API.request(:delete, "ip_leases/#{uuid}")
        self.mac_lease.ip_leases.delete_if{|i| i.uuid == uuid}
        reload
      end
    end

    class Datapath < Base
      attr_accessor :name

      class << self
        def api_name
          "datapaths"
        end
      end

      def initialize(options)
        @node_id = options.fetch(:node_id)
        @dpid = options.fetch(:dpid)

        @display_name = options[:display_name]

        @datapath_networks = []
        @datapath_networks_loaded = false
        @datapath_segments = []
        @datapath_segments_loaded = false
      end

      def destroy
        API.request(:delete, "datapaths/#{uuid}")
        reload
      end

      def add_datapath_network(network_uuid, options)
        API.request(:post, "datapaths/#{uuid}/networks/#{network_uuid}", options) do |response|
          @datapath_networks << OpenStruct.new(response)
        end
      end

      def remove_datapath_network(network_uuid)
        API.request(:delete, "datapaths/#{uuid}/networks/#{network_uuid}") do |response|
          @datapath_networks.delete_if { |record| record.uuid == network_uuid }
        end
      end

      def add_datapath_segment(segment_uuid, options)
        API.request(:post, "datapaths/#{uuid}/segments/#{segment_uuid}", options) do |response|
          @datapath_segments << OpenStruct.new(response)
        end
      end

      def remove_datapath_segment(segment_uuid)
        API.request(:delete, "datapaths/#{uuid}/segments/#{segment_uuid}") do |response|
          @datapath_segments.delete_if { |record| record.uuid == segment_uuid }
        end
      end

    end

    class DnsService < Base
      attr_accessor :public_dns
      attr_accessor :network_servie_uuid

      class << self
        def api_name
          "dns_services"
        end
      end

      def initialize(options)
        @public_dns = options[:public_dns]
        @network_servie_uuid = options[:network_servie_uuid]
        @dns_records = []
      end

      def update_public_dns(public_dns)
        API.request(:put, "#{api_name}/#{uuid}", public_dns: public_dns)
        @public_dns = public_dns
      end

      def destroy
        API.request(:delete, "#{api_name}/#{uuid}")
        reload
      end

      def add_dns_record(options)
        API.request(:post, "#{api_name}/#{uuid}/dns_records", options) do |response|
          @dns_records << OpenStruct.new(response)
        end
      end

      def remove_dns_record(dns_record_uuid)
        API.request(:delete, "#{api_name}/#{uuid}/dns_records/#{dns_record_uuid}") do |response|

          @dns_records.delete_if { |record| record.uuid == dns_record_uuid }
        end
      end
    end

    class IpRetentionContainer < Base
      attr_accessor :lease_time
      attr_accessor :grace_time

      class << self
        def api_name
          "ip_retention_containers"
        end
      end

      def initialize(options)
        @lease_time = options[:lease_time].to_i
        @grace_time = options[:grace_time].to_i
        @ip_retentions = []
      end

      def ip_retentions(options = {})
        if @ip_retentions.empty? || options[:reload]
          API.request(:get, "#{api_name}/#{uuid}/ip_retentions", limit: 1000) do |response|
            @ip_retentions = response[:items].map { |i| IpRetention.new(i) }
          end
        end
        @ip_retentions
      end

      def destroy
        API.request(:delete, "#{api_name}/#{uuid}")
        reload
      end
    end

    class IpRetention
      attr_accessor :leased_at
      attr_accessor :released_at
      def initialize(options)
        @leased_at = Time.parse(options[:leased_at])
        @released_at = Time.parse(options[:released_at]) if options[:released_at]
      end
    end

    class Topology < Base
      class << self
        def delete(tp_uuid)
          API.request(:delete, "topologies/#{tp_uuid}")
        end

        def add_mrg(tp_uuid, mrg_uuid)
          API.request(:post, "topologies/#{tp_uuid}/mac_range_groups/#{mrg_uuid}")
        end

        def add_network(tp_uuid, nw_uuid)
          API.request(:post, "topologies/#{tp_uuid}/networks/#{nw_uuid}")
        end

        def add_segment(tp_uuid, seg_uuid)
          API.request(:post, "topologies/#{tp_uuid}/segments/#{seg_uuid}")
        end

        def remove_mrg(tp_uuid, mrg_uuid)
          API.request(:delete, "topologies/#{tp_uuid}/mac_range_groups/#{mrg_uuid}")
        end

        def remove_network(tp_uuid, nw_uuid)
          API.request(:delete, "topologies/#{tp_uuid}/networks/#{nw_uuid}")
        end

        def remove_segment(tp_uuid, seg_uuid)
          API.request(:delete, "topologies/#{tp_uuid}/segments/#{seg_uuid}")
        end

      end
    end

  end
end
