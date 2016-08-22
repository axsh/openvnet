module Vnspec
  module API
    class Base
      include Logger
      include Config
      include SSH

      def request(method, url, params = {}, headers = {}, &block)
        raise NotImplementedError
      end
    end
  end
end
