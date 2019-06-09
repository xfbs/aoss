require 'git'
require 'octokit'
require 'aoss/repo'
require 'pathname'
require 'thread/pool'

module Aoss
  class Push
    def initialize
      @repos = []
    end

    def run opts
      @repos = Pathname.new(opts.dir)
        .children
        .select{|c| c.directory? && (c + ".git").directory?}
        .map{|c| "#{c.basename}/"}
        .map{|c| Repo.new logger: opts.log, name: c, basedir: opts.dir}

      opts.log.info "found #{@repos.length} repositories"

      client = Octokit::Client.new(:access_token => opts.token)
      opts.log.info "logged in to github API as #{client.user.name}"

      bad = []

      pool = Thread.pool(opts.cpus)
      @repos.each do |repo|
        #pool.process do
          begin
            repo.push(client: client, org: opts.org)
          rescue => e
            @log.error "[#{repo.name}] error while pushing."
            @log.error e
            bad << repo.name
          end
        #end
      end
      pool.wait

      unless bad.empty?
        @log.error "errors while pushing #{bad.join(', ')}."
      end
    end
  end
end
