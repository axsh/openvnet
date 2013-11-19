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
      def self.inherited(klass)
        klass.class_eval do
          prepend(BaseModule)
        end
      end

      def ==(other)
        self.uuid == other.uuid
      end
    end

    class Interface < Base
      attr_accessor :name
      attr_reader :mac_leases

      class << self
        def all
          API.request(:get, "interfaces") do |response|
            response.map do |r|
              self.new(r)
              # TODO associations
            end
          end
        end

        def create(options)
          API.request(:post, "interfaces", options) do |response|
            return self.new(options.merge(uuid: response[:uuid])).tap do |interface|
              if options[:mac_address] && response[:mac_leases].first
                mac_lease = response[:mac_leases].first
                interface.mac_leases << Models::MacLease.new(uuid: mac_lease[:uuid], interface: interface,  mac_address: mac_lease[:mac_address]).tap do |mac_lease|
                  if options[:network_uuid] && options[:ipv4_address] && response[:ip_leases].first
                    ip_lease = response[:ip_leases].first
                    mac_lease.ip_leases << Models::IpLease.new(uuid: ip_lease[:uuid], mac_lease: mac_lease, ipv4_address: ip_lease[:ipv4_address], network_uuid: ip_lease[:network_uuid])
                  end
                end
              end
            end
          end
        end
      end

      def initialize(options)
        @name = options[:name]
        @mac_leases = []
      end

      def destroy
        API.request(:delete, "interfaces/#{uuid}")
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
    end

    class MacLease < Base
      attr_reader :interface
      attr_reader :mac_address
      attr_reader :ip_leases

      class << self
        def create(interface, options)
          API.request(:post, "mac_leases", options.merge(interface_uuid: interface.uuid)) do |response|
            return self.new(options.merge(uuid: response[:uuid:], interface: interface))
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
  end
end
