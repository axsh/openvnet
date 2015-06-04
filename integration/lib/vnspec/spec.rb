# -*- coding: utf-8 -*-
module Vnspec
  class SPec
    class << self
      include SSH
      include Logger
      include Config

      def exec(name = nil)
        spec_file = name ? "spec/#{name}_spec.rb" : ""
        logger.info("-" * 50)
        logger.info("executing spec: #{name}")
        logger.info("-" * 50)

        #require_relative 'spec/spec_helper'
        #json_formatter = RSpec.configuration.formatters.find{|f| f.class == RSpec::Core::Formatters::JsonFormatter}

        #RSpec::Core::Runner.run([File.expand_path("../spec/#{name}_spec.rb", __FILE__)])
        #json_formatter.output_hash.tap {|hash| logger. hash}

        system("cd #{File.expand_path(File.dirname(__FILE__))}; bundle exec rspec #{spec_file}")
      end
    end
  end
end
