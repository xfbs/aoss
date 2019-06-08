require 'nokogiri'
require 'open-uri'
require 'aoss/dir_list'

module Aoss
  class Sync
    @repos = []

    def initialize
    end

    def run
      open(APPLE_OPENSOURCE) do |response|
        body = DirList.new(response.read)

        p body.entries
      end
    end
  end
end
