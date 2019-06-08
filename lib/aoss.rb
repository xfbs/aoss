require "aoss/version"
require "aoss/sync"
require 'logger'
require 'ostruct'

module Aoss
  APPLE_OPENSOURCE = "https://opensource.apple.com/source/"

  class Error < StandardError; end
  # Your code goes here...

  def self.run(args)
    opts = OpenStruct.new
    opts.log = Logger.new(STDOUT)
    opts.dir = args[0]
    opts.cpus = 4
    Sync.new.run(opts)
  end
end
