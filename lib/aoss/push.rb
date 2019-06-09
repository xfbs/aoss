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

      pool = Thread.pool(opts.cpus)
      @repos.each do |repo|
        #pool.process do
          repo.push(client: client, org: opts.org)
        #end
      end
      pool.wait
    end
  end
end
