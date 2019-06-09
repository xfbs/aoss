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

      # filter bad repos out
      # these all have underscores in their version names, which I don't know how to handle.
      bad = ["AppleCore99PE", "AppleMacRISC2PE", "CarbonHeaders", "IOSCSIArchitectureModelFamily", "IOUSBMassStorageClass", "JavaScriptCore", "WebCore", "apache_mod_xsendfile", "blast", "mDNSResponder", "seeds"]
      # these have some odd file permission issues
      bad += ["gdb", "gdbforcw", "cctools"]

      #@repos = @repos.filter{|r| !bad.include? r.name}[200..311]

      pool = Thread.pool(opts.cpus)
      @repos.each do |repo|
        pool.process do
          # create git repo and fetch tags from remote
          repo.setup
          #repo.fetch_tags
        end
        pool.process do
          # fetch entries from apple opensource
          repo.fetch_entries
        end
      end
      # wait for all of that to be done
      pool.wait

      # sync repos
      @repos.each do |repo|
        pool.process do
          begin
            repo.sync
          rescue => e
            opts.log.error "[#{repo.name}] error while syncing"
            opts.log.error e
            bad << repo.name
          end
        end
      end
      pool.wait

      opts.log.error "RESULT: syncing complete, but didn't work for #{bad.join(', ')}. these need to be handled manually."
    end
  end
end
