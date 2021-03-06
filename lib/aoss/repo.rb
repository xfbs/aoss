require 'open-uri'
require 'aoss/dir_list'
require 'git'
require 'fileutils'
require 'aoss/tar_file'
require 'tempfile'

module Aoss
  class Repo
    attr_accessor :name, :path

    def initialize logger:, name:, url: nil, basedir:
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

        # somehow Git.init doesn't work if the path is in a git repo.
        #Git.init(@path, :log => @log)
        `git init "#@path"`
      end

      @git = Git.open(@path, :log => @log)
    end

    def push(client:, org:)
      @git = Git.open(@path, :log => @log)

      unless @git.remotes.any?{|r| r.url =~ /github\.com/}
        @log.info "[#@name] doesn't have a remote, checking github."
        begin
          repo = client.repository("#{org}/#{@name}")
        rescue Octokit::NotFound
          @log.info "[#@name] repository #{org}/#{@name} not found, creating it."
          repo = client.create_repository(@name, :organization => org)
        end

        @git.add_remote("origin", "git@github.com:#{org}/#@name")
      end

      if @git.is_branch? 'master'
        @log.info "[#@name] pushing to github."
        @git.push("origin", "master", :force => true, :tags => true)
      else
        @log.error "[#@name] branch master doesn't exist, skipping."
      end
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
        if /^v[\da-z\.]+$/ =~ tag.name
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
              @log.warn "[#{@name}] current version #{version} lies in the past"
            elsif date.year < 1995 || date.year > 2020
              @log.error "[#{@name}] illegal date encountered in #{version}: #{date}"
            end
            prev_date = date

            # create commit and add tag
            @git.add()
            begin
              @git.commit "Updates to version #{version}.", :date => date.to_s, :author => "John Appleseed <john@apple.com>"
            rescue Git::GitExecuteError => e
              @log.error "[#{@name}] exception while doing a git commit"
              raise e
            end
            @git.add_tag "v#{version}"
            @log.info "[#{@name}] added version #{version} to the repository"
          end
        end
      end
    end
  end
end
