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
      @entries = {}
      @basedir = basedir
      @path = File.join(@basedir, @name)

      unless @name =~ /^[a-zA-Z0-9_]+\/$/
        throw "bad formatting at #{name}"
      end

      @name = name[0..-2]
    end

    # create and open git repo
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

      @git = Git.open(File.join(@basedir, @name), :log => @log)
    end

    # get entries from apple
    def fetch_entries
      @log.info "fetching entries for #{@name}"
      DirList.new(open(@url)).entries.each do |entry|
        @entries[Gem::Version.new(parse_entry(entry))] = entry
      end
      @log.info "got #{@entries.length} entries for #{@name}"
    end

    # get tags from remotes
    def fetch_tags
      @git.remotes.each do |remote|
        @git.fetch remote
      end
    end

    def parse_entry entry
      /^#{@name}-([\d\.]+)\.tar\.gz$/.match(entry)[1]
    end

    def sync
      sorted_versions = @entries.keys.sort
      tags = {}
      @git.tags.each do |tag|
        if /^r[\d\.]+$/ =~ tag.name
          tags[Gem::Version.new(tag.name[1..-1])] = tag
        end
      end

      sorted_versions.each do |version|
        @log.info "#{version} has tag: #{tags[version].nil?}"
      end
    end
  end
end
