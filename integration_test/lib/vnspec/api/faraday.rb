module Vnspec
  module API
    class Faraday < Base
      def request(method, url, params = {}, headers = {}, &block)
        old_params, params = params, params.dup
        conn.run_request(method, "/api/#{url}", params, headers).tap do |response|
          logger.debug "params:"
          logger.debug old_params
          logger.debug "response:"
          logger.debug response.body

          # TODO status check
          raise "Request failed: #{response.status}" unless response.status.to_s =~ /^20\d$/

          return yield({ body: JSON.parse(response.body) }.symbolize_keys[:body]) if block_given?
        end
      end

      private
      def conn
        @conn ||= ::Faraday.new(:url => "http://#{config[:webapi][:host]}:#{config[:webapi][:port]}") do |builder|
          builder.request  :url_encoded
          builder.response :logger, logger
          builder.adapter  :net_http
        end
      end
    end
  end
end
