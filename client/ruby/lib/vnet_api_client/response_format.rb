# -*- coding: utf-8 -*-

module VNetAPIClient
  module ResponseFormats

    def self.[](format)
      case format
      when :json
        Json.new
      else
        raise "Unknown response format: #{format}"
      end
    end

    class Format
      def parse(response)
        raise NotImplementedError
      end
    end

    class Json < Format
      def parse(response)
        JSON.parse(response.body)
      end
    end

  end
end
