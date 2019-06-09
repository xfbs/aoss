require "aoss/version"
require "aoss/sync"
require 'logger'
require 'ostruct'

module Aoss
  APPLE_OPENSOURCE = "https://opensource.apple.com/tarballs/"

  class Error < StandardError; end
  # Your code goes here...

  def self.run(args)
    if args.length < 2
      puts help
    else
      opts = OpenStruct.new
      opts.log = Logger.new(STDOUT)
      opts.log.sev_threshold = Logger::DEBUG
      opts.dir = args[0]
      opts.cpus = 4
      case args.first
      when 'sync'
        Sync.new.run(opts)
      when 'push'
        Push.new.run(opts)
      else
        puts help
      end
    end
  end

  def self.help
    "Usage: aoss [push | sync] <dir>"
  end
end
