require 'open-uri'
require 'aoss/dir_list'
require 'git'
require 'fileutils'

module Aoss
  class Repo
    def initialize logger:, name:, url:, basedir:
      @log = logger
      @name = name
      @url = url
      @entries = []
      @basedir = basedir
      @path = File.join(@basedir, @name)
    end

    def setup
      # create folder if it doesn't exist
      unless Dir.exists? @path
        @log.info "creating directory for repo #{@name}"
        FileUtils.mkdir(@path)
      end

      # create repo if there isn't one
      unless Dir.exists? File.join(@path, ".git")
        @log.info "creating repository for repo #{@name}"
        Git.init(@path, :log => @log)
      end

      @repo = Git.open(File.join(@basedir, @name), :log => @log)
      @log.info "git repo worked: #{@repo.repo}"
    end

    def fetch_entries
      @log.info "fetching tags for #{@name}"
      @entries = DirList.new(open(@url)).entries
      @log.info "got #{@entries.length} for #{@name}"
    end

    def fetch_tags
    end
  end
end
