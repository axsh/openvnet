module Vnspec
  module API
    class Vnctl < Base
      def request(method, url, params = {}, headers = {}, &block)
        old_params, params = params, params.dup

        args = build_args(method, url, params)
        address = config[:webapi][:host]
        command = "vnctl #{args.join(" ")}"
        logger.debug command
        logger.debug "params:"
        logger.debug old_params

        raw_response = ssh(address, command)
        if raw_response[:exit_code] != 0 || !raw_response[:stderr].empty?
          raise "Request failed: #{raw_response[:stderr]}"
        end

        begin
          response = YAML.load(raw_response[:stdout])
        rescue
          logger.error(
            "An error occurred while trying to parse the following WebAPI reply as Yaml.\n%s" %
            raw_response[:stdout])

          raise
        end

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

        response
      end

      private

      def build_args(method, url, params)
        values = url.split("/").compact
        # datapath networks show dp-3 nw-public
        args = [values[0]]

        # Convert relation WebAPI calls to vnctl arguments.
        # For example 'POST datapaths/dp-xxxx/networks/nw-yyyy'
        # becomes: 'vnctl datapaths networks add dp-xxxx nw-yyyy'
        url.match(%r([^/]+/[^/]+/([^/]+))).tap { |relation_capture|
          next if relation_capture.nil?

          relation_name = relation_capture.captures.first

          # Currently 'PUT interfaces/:uuid/rename' is the only API route that
          # does not follow the REST standard. This is a quick hack to work
          # around it.
          args << relation_name unless relation_name == 'rename'
        }

        args += [convert_method(method, url), values[1], values[3]].compact
        params.keys.each do |key|
          args << %Q(--#{key} "#{params[key]}")
        end

        args
      end

      def convert_method(method, url)
        case method
        when :get
          :show
        when :post
          :add
        when :delete
          :del
        when :put
          get_put_command(url)
        else
          "undefined method: #{method}"
        end
      end

      # TODO: Fix the API to be REST compatible.
      def get_put_command(url)
        case
        when url =~ %r([^/]+/rename$)
          :rename
        else
          :modify
        end
      end

    end
  end
end
