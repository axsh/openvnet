module Vnspec
  module API
    module ModuleMethods
      include Logger
      include Config

      def request(*args, &block)
        @api ||= api_for(config[:api_adapter])
        @api.request(*args, &block)
      end

      def api_for(method)
        case method
        when :vnctl
          Vnctl.new
        when :faraday
          Faraday.new
        else
          raise "undefined api method: #{method}"
        end
      end
    end
    extend ModuleMethods
  end
end
