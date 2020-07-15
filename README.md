# ActiveSfdc

ActiveRecord connection layer with Salesforce.

### WARNING: THIS GEM IS IN A VERY EARLY STAGE.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_salesforce'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_salesforce

## Usage

Define Salesforce objects in your codebase just like ActiveRecord models. Just specify
which fields should be pulled by default, and you're good to go!

```
class Contact < ActiveSfdc::Base
  def projection_fields
  	{
  		Name: :string,
  		LastName: :string
  	}
  end
end

> Contact.all.take(10) #> will perform an SOQL query like
# SELECT Id, Name, LastName FROM Contact LIMIT 10
# and map all the results to active record objects.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SUSE/active_salesforce.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
