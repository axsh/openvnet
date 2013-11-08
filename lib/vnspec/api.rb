module Vnspec
  module API
    module ModuleMethods
      include Logger
      include Config

      def request(method, url, params = {}, headers = {}, &block)
        old_params, params = params, params.dup
        conn.run_request(method, "/api/#{url}", params, headers).tap do |response|
          logger.debug "params:"
          logger.debug old_params
          logger.debug "response:"
          logger.debug response.body

          # TODO status check
          raise "Request failed: #{response.status}" unless response.status.to_s =~ /^20\d$/

          yield JSON.parse(response.body) if block_given?
        end
      end

      private
      def conn
        @conn ||= Faraday.new(:url => "http://#{config[:webapi][:host]}:#{config[:webapi][:port]}") do |builder|
          builder.request  :url_encoded
          builder.response :logger, logger
          builder.adapter  :net_http
        end
      end
    end

    extend ModuleMethods
  end
end
