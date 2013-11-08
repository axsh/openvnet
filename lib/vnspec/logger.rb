# https://gist.github.com/clowder/3639600
class MultiLogger
  attr_reader :level

  def initialize(args={})
    @level = args[:level] || Logger::Severity::DEBUG
    @loggers = []

    Array(args[:loggers]).each { |logger| add_logger(logger) }
  end

  def add_logger(logger)
    logger.level = level
    @loggers << logger
  end

  def level=(level)
    @level = level
    @loggers.each { |logger| logger.level = level }
  end

  def close
    @loggers.map(&:close)
  end

  def add(level, *args)
    @loggers.each { |logger| logger.add(level, args) }
  end

  Logger::Severity.constants.each do |level|
    define_method(level.downcase) do |*args, &block|
      @loggers.each { |logger| logger.send(level.downcase, *args, &block) }
    end

    define_method("#{ level.downcase }?".to_sym) do
      @level <= Logger::Severity.const_get(level)
    end
  end
end

module Vnspec
  module Logger
    def logger
      unless @logger
        level = ::Logger.const_get(config[:log_level].to_s.upcase)
        std_logger = ::Logger.new(STDOUT)
        std_logger.formatter = proc do |severity, datetime, progname, msg|
          "#{msg}\n"
        end
        @logger = ::MultiLogger.new(level: level, loggers: [
          std_logger,
          ::Logger.new(File.expand_path("../../log/#{config[:env]}-#{Time.now.strftime('%Y%m%d%H%M%S')}.log", File.dirname(__FILE__))),
        ])
      end
      @logger
    end
  end
end
