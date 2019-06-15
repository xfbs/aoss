require 'date'
require 'tempfile'
require 'fileutils'

module Aoss
  class TarFile
    def initialize file
      @file = file

      unless file.respond_to? :path
        tmp = Tempfile.new('aoss')
        tmp.binmode
        tmp.write file.read
        tmp.flush
        @file = tmp
      end
    end

    def extract(strip_components: 0, destdir:)
      `tar --strip-components #{strip_components} -xf "#{@file.path}" -C "#{destdir}"`

      # fix permissions
      FileUtils.chmod_R("u+w", destdir)
    end

    def date(file: nil)
      date = `tar -tvf #{@file.path} #{file}`.split("\n").first.split(" ")[3..4].join(" ")
      puts "parsing date #{date}"
      d = Date.parse(date)
      DateTime.new(d.year, d.month, d.day, 9, 41, 0, 0)
    end
  end
end
