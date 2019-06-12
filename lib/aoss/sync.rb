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
      bad = ["AppleCore99PE", "AppleMacRISC2PE", "CarbonHeaders", "IOSCSIArchitectureModelFamily", "IOUSBMassStorageClass", "JavaScriptCore", "WebCore", "apache_mod_xsendfile", "blast", "mDNSResponder", "seeds", "CF", "BerkeleyDB", "IOKitUser", "Libc", "Libsystem", "Liby", "OpenAL", "PowerManagement", "X11apps", "X11fonts", "X11libs", "X11misc", "X11proto", "X11server", "WTF", "apr", "apache_mod_ssl", "bootstrap_cmds", "diskdev_cmds", "doc_cmds", "dyld", "curl", "bmalloc", "configd", "file_cmds", "files", "gas", "gcc3", "gcc_os", "gcc_os_35", "gccfast", "gimp_print", "gpatch", "groff", "gssd", "headerdoc", "libdispatch", "libiconv", "libplatform", "libstdcxx", "lukemftp", "lukemftpd", "msdosfs", "ntfs", "rsync", "security_certificates", "security_ocspd", "top", "vim", "zip", "AppleI2C", "AppleMediaBay", "AppleThermal", "IOATAFamily", "OpenPAM", "awk", "bash", "expat", "ld64", "less", "libauto"]
      # these have some odd file permission issues
      bad += ["gdb", "gdbforcw", "cctools"]

      @repos = @repos.filter{|r| !bad.include? r.name}

      @repos.each do |repo|
        repo.setup
        repo.fetch_entries
      end

      # sync repos
      @repos.each do |repo|
        begin
          repo.sync
        rescue => e
          opts.log.error "[#{repo.name}] error while syncing"
          opts.log.error e
          bad << repo.name
        end
      end

      opts.log.error "RESULT: syncing complete, but didn't work for #{bad.join(', ')}. these need to be handled manually."
    end
  end
end
