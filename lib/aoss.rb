require "aoss/version"
require "aoss/sync"

module Aoss
  APPLE_OPENSOURCE = "https://opensource.apple.com/source/"

  class Error < StandardError; end
  # Your code goes here...

  def self.run
    Sync.new.run
  end
end
