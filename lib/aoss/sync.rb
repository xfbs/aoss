require 'nokogiri'
require 'open-uri'
require 'aoss/dir_list'
require 'aoss/repo'
require 'thread/pool'

module Aoss
  class Sync
    def initialize
      @repos = []
    end

    def run(opts)
      opts.log.info "fetching list of open source projects"
      open(APPLE_OPENSOURCE) do |response|
        body = DirList.new(response.read)
        opts.log.info "found #{body.entries.length} open source projects"

        body.entries.each do |entry|
          @repos << Repo.new(logger: opts.log, name: entry[0..-1], url: APPLE_OPENSOURCE + entry, basedir: opts.dir)
        end
      end

      # FIXME limit repos for debug reasons
      @repos = @repos[0..2]

      pool = Thread.pool(opts.cpus)
      @repos.each do |repo|
        #pool.process do
          repo.setup
          repo.fetch_tags
        #end
        #pool.process do
          repo.fetch_entries
        #end
      end
      pool.wait
      @repos.each do |repo|
        repo.sync
      end
    end
  end
end
