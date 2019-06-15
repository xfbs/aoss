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
      bad = ["AppleCore99PE", "AppleMacRISC2PE", "CarbonHeaders", "IOSCSIArchitectureModelFamily", "IOUSBMassStorageClass", "JavaScriptCore", "WebCore", "apache_mod_xsendfile", "blast", "mDNSResponder", "seeds", "CF", "BerkeleyDB", "IOKitUser", "Libc", "Libsystem", "Liby", "OpenAL", "PowerManagement", "WTF", "apr", "apache_mod_ssl", "bootstrap_cmds", "doc_cmds", "dyld", "curl", "bmalloc", "configd", "file_cmds", "files", "gas", "gpatch", "groff", "gssd", "headerdoc", "libdispatch", "libiconv", "libplatform", "lukemftp", "lukemftpd", "msdosfs", "ntfs", "rsync", "security_certificates", "security_ocspd", "top", "vim", "zip", "AppleMediaBay", "IOATAFamily", "OpenPAM", "awk", "bash", "expat", "less", "libauto", "lldb"]

      @repos = @repos.filter{|r| bad.include? r.name}

      bad = []
      good = []

      @repos.each do |repo|
        begin
          repo.setup
          repo.fetch_entries
          repo.sync
        rescue => e
          opts.log.error "[#{repo.name}] error while syncing"
          opts.log.error e
          bad << repo.name
          FileUtils.rm_rf repo.path
        else
          good << repo.name
        end
      end

      opts.log.info "RESULT: worked for #{good.join(', ')}."
      opts.log.error "RESULT: syncing complete, but didn't work for #{bad.join(', ')}. these need to be handled manually."
    end
  end
end
