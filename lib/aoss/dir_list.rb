require 'nokogiri'

module Aoss
  class DirList
    def initialize data
      @data = Nokogiri::HTML(data)
      parse
    end

    def parse
      @entries = @data.css('table tr td a').each.filter{|n| n.content != ""}.map{|n| n.content}[1..]
    end

    def entries
      @entries
    end
  end
end
