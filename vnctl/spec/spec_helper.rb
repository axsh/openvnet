# -*- coding: utf-8 -*-
require 'rubygems'
require 'bundler'
Bundler.setup(:default)
#Bundler.require(:default, :test)
Bundler.require(:test)

require 'thor'
require "thor/group"
require 'vnctl'

# Set shell to basic
$0 = "vnctl"
ARGV.clear

RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  alias silence capture
end
