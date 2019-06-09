# Apple Open Source Sync

Syncs all projects from [Apple Open Source](https://opensource.apple.com/) to a folder, and converts them into git repositories with the individual versions as tags and commits with the correct time.

It currently mostly works but is broken for a few projects due to inconsistencies with naming.

## Installation

Install it yourself as:

    $ gem install aoss

## Usage

Run the `aoss` tool with the name of a directory to save the git repositories to. Be aware that running the tool will take quite a lot of time.

    $ aoss sync path/to/repos/

If you would like to push all these repositories to github, there's also an option to do so. You need to generate a personal access token with `admin:org` rights. You also need a namespace to push the repositories under, which can be an organisation. Then you run the tool like this:

    $ aoss push path/to/repos/ <token> [<org>]

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/aoss. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Aoss project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/aoss/blob/master/CODE_OF_CONDUCT.md).
