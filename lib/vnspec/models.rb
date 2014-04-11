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
                self.new(r)
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
      end

      def ==(other)
        self.uuid == other.uuid
      end

      def api_name
        self.class.api_name
      end
    end

    class Interface < Base
      attr_reader :mac_leases

      class << self
        def api_name
          "interfaces"
        end

        def all(options = {})
          API.request(:get, api_name, limit: 1000) do |response|
            response[:items].map do |r|
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

        def create(options)
          API.request(:post, "interfaces", options)
          find(options[:uuid], reload: true)
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
        self.class.find(uuid, reload: true)
      end

      def destroy
        API.request(:delete, "interfaces/#{uuid}")
        self.class.find(uuid, reload: true)
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

      class << self
        def create(interface, options)
          API.request(:post, "mac_leases", options.merge(interface_uuid: interface.uuid)) do |response|
            return self.new(options.merge(uuid: response[:uuid], interface: interface))
          end
        end
      end

      def initialize(options)
        @interface = options[:interface]
        @mac_address = options[:mac_address]
        @ip_leases = []
      end

      def destroy
        API.request(:delete, "mac_leases/#{uuid}")
        self.interface.mac_leases.delete_if{|m| m.uuid == uuid}
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
        def create(mac_lease, options)
          API.request(:post, "ip_leases", options.merge(mac_lease_uuid: mac_lease.uuid)) do |response|
            return self.new(options.merge(uuid: response[:uuid], mac_lease: mac_lease)).tap do |instance|
            end
          end
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
      end
    end

    class Datapath < Base
      attr_accessor :name

      class << self
        def api_name
          "datapaths"
        end

        def create(options)
          API.request(:post, "datapaths", options) do |response|
            return self.new(options.merge(uuid: response[:uuid]))
          end
        end
      end

      def initialize(options)
        @node_id = options.fetch(:node_id)
        @dpid = options.fetch(:dpid)

        @display_name = options[:display_name]
        @datapath_networks = []
        @datapath_networks_loaded = false
      end

      def destroy
        API.request(:delete, "datapaths/#{uuid}")
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
    end

    class DnsService < Base
      attr_accessor :public_dns
      attr_accessor :network_servie_uuid

      class << self
        def api_name
          "dns_services"
        end

        def create(options)
          API.request(:post, api_name, options) do |response|
            return self.new(options.merge(uuid: response[:uuid]))
          end
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
  end
end
