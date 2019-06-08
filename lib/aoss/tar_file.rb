require 'date'
require 'tempfile'

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
    end

    def date(file: nil)
      d = Date.parse(`tar -qtvf #{@file.path} #{file}`.split(" ")[5..7].join(" "))
      DateTime.new(d.year, d.month, d.day, 9, 41, 0, 0)
    end
  end
end
