require 'nokogiri'
require 'open-uri'


module Aoss
  class Sync
    @repos = []

    def initialize
    end

    def run
      open(APPLE_OPENSOURCE) do |response|
        body = response.read

        p body
      end
    end
  end
end
