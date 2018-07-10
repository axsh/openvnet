# -*- coding: utf-8 -*-
module Vnspec
  class SPec
    class << self
      include SSH
      include Logger
      include Config

      def exec(name = nil)
        spec_file = name ? "spec/#{name}_spec.rb" : ""

        system("cd #{File.expand_path(File.dirname(__FILE__))}; bundle exec rspec #{spec_file}")
      end
    end
  end
end
