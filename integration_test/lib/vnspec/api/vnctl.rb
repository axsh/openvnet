module Vnspec
  module API
    class Vnctl < Base
      def request(method, url, params = {}, headers = {}, &block)
        old_params, params = params, params.dup

        args = build_args(method, url, params)
        address = config[:webapi][:host]
        command = "cd #{config[:vnet_path]}/client/vnctl && bundle exec bin/vnctl #{args.join(" ")}"
        logger.debug command
        logger.debug "params:"
        logger.debug old_params

        raw_response = ssh(address, command)
        if raw_response[:exit_code] != 0 || !raw_response[:stderr].empty?
          raise "Request failed: #{raw_response[:stderr]}"
        end

        YAML.load(raw_response[:stdout]).tap do |response|
          logger.debug "response:"
          logger.debug response

          if response.is_a?(Hash)
            response = response.symbolize_keys
            if response[:error]
              raise "Request failed: #{response[:error]} #{response[:code]} #{response[:message]}"
            end
          elsif response.is_a?(String)
            raise "Request failed: #{response}"
          end

          return yield(response) if block_given?
        end
      end

      private
      def build_args(method, url, params)
        values = url.split("/").compact
        # datapath networks show dp-3 nw-public
        args = [values[0]]
        args <<
          case url
          when %r(^datapaths/[^/]+/networks)
            :networks
          when %r(^datapaths/[^/]+/route_links)
            :route_links
          when %r(^interfaces/[^/]+/security_groups)
            :security_groups
          when %r(^dns_services/[^/]+/dns_records)
            :dns_records
          end
        args += [convert_method(method), values[1], values[3]].compact
        params.keys.each do |key|
          args << %Q(--#{key} "#{params[key]}")
        end
        args
      end

      def convert_method(method)
        case method
        when :get
          :show
        when :post
          :add
        when :put
          :modify
        when :delete
          :del
        else
          "undefined method: #{method}"
        end
      end
    end
  end
end
