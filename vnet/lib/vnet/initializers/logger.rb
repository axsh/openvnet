module Vnet::Initializers
  class Logger
    def self.run(filename)
      log_dir =  Vnet::LOG_DIRECTORY
      FileUtils.mkdir_p(log_dir) unless Dir.exists?(log_dir)
      Celluloid.logger = ::Logger.new(File.join(log_dir, filename))
      Vnet.logger = Celluloid.logger
    end
  end
end
