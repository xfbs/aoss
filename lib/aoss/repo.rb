require 'open-uri'
require 'aoss/dir_list'
require 'git'
require 'fileutils'
require 'aoss/tar_file'
require 'tempfile'

module Aoss
  class Repo
    attr_accessor :name

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
        @log.info "[#{@name}] creating directory for repo"
        FileUtils.mkdir(@path)
      end

      # create repo if there isn't one
      unless Dir.exists? File.join(@path, ".git")
        @log.info "[#{@name}] creating repository for repo"
        Git.init(@path, :log => @log)
      end

      @git = Git.open(File.join(@basedir, @name), :log => @log)
    end

    # get entries from apple
    def fetch_entries
      @log.info "[#{@name}] fetching entries for"
      DirList.new(open(@url)).entries.each do |entry|
        @entries[Gem::Version.new(parse_entry(entry))] = entry
      end
      @log.info "[#{@name}] got #{@entries.length} entries"
    end

    # get tags from remotes
    def fetch_tags
      @git.remotes.each do |remote|
        @git.fetch remote
      end
    end

    def parse_entry entry
      unless /^#{@name}-[\da-z\.]+\.tar\.gz/ =~ entry
        @log.warn "[#{@name}] entry might be malformed: #{entry}"
      end

      /^#{@name}-([\da-zA-Z\.]+)\.tar\.gz$/.match(entry)[1]
    end

    def sync
      sorted_versions = @entries.keys.sort
      tags = {}
      @git.tags.each do |tag|
        if /^r[\da-z\.]+$/ =~ tag.name
          tags[Gem::Version.new(tag.name[1..-1])] = tag
        end
      end

      prev_date = DateTime.new(1980)
      sorted_versions.each do |version|
        # only do this if a tag with this version doesn't exist yet
        if tags[version].nil?
          @log.info "[#{@name}] creating version #{version} by downloading #{@entries[version]}"
          open(File.join(@url, @entries[version])) do |file|
            # make sure we're backed by a file.
            if file === StringIO
              f = Tempfile.new('aoss')
              f.binmode
              f << file.read
              file = f
            end

            @log.info "[#{@name}] have file for version #{version}, extracting"
            FileUtils.rm_r Dir["#{@path}/*"]
            tar = TarFile.new(file)
            tar.extract(strip_components: 1, destdir: @path)

            # extract and sanity check date
            date = tar.date(file: @entries[version].chomp(".tar.gz"))
            if date <= prev_date
              @log.error "[#{@name}] current version #{version} lies in the past"
            elsif date.year < 1995 || date.year > 2020
              @log.error "[#{@name}] illegal date encountered in #{version}: #{date}"
            end
            prev_date = date

            # create commit and add tag
            @git.add(:all=>true)
            @git.commit "Revision #{version}.", :date => date.to_s
            @git.add_tag "r#{version}"
            @log.info "[#{@name}] added version #{version} to the repository"
          end
        end
      end
    end
  end
end
