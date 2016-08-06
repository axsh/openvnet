# -*- coding: utf-8 -*-
require 'yaml'
require 'json'
require 'erb'
require 'logger'
require 'net/ssh/multi'
require 'net/scp'
require 'faraday_middleware'
require 'parallel'
require 'rspec'
require 'pp'
require 'ipaddress'
# for debug
require 'pry'

require_relative 'ext/hash'
require_relative 'ext/erb'
require_relative 'vnspec/logger'
require_relative 'vnspec/parallel_module'
require_relative 'vnspec/config'
require_relative 'vnspec/ssh'
require_relative 'vnspec/invoker'
require_relative 'vnspec/api'
require_relative 'vnspec/api/base'
require_relative 'vnspec/api/faraday'
require_relative 'vnspec/api/vnctl'
require_relative 'vnspec/dataset'
require_relative 'vnspec/vnet'
require_relative 'vnspec/models'
require_relative 'vnspec/vm'
require_relative 'vnspec/legacy'
require_relative 'vnspec/spec'

module Vnspec
  ROOT = File.expand_path("../", File.dirname(__FILE__))
end
