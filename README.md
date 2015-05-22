Geocoder Olleh
==============

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/geocoder/olleh`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'geocoder-olleh'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install geocoder-olleh

## Olleh (`:olleh`)

* **API key**: required (set `Geocoder.configure(:api_key => [app_id, app_key])`)
* **Quota**: Dependant on service plan
* **Region**: South Korea
* **SSL support**: no
* **Languages**: Korean
* **Documentation**: https://www.ollehmap.com/spacedata/
* **Terms of Service**: https://www.ollehmap.com/spacedata/#이용약관
* **Limitations**: Only for commercial use. For commercial usage please check https://www.ollehmap.com/guide/

Caching
-------

It's a good idea, when relying on any external service, to cache retrieved data. When implemented correctly it improves your app's response time and stability. It's easy to cache geocoding results with Geocoder, just configure a cache store:

    Geocoder.configure(:cache => Redis.new)

This example uses Redis, but the cache store can be any object that supports these methods:

* `store#[](key)` or `#get` or `#read` - retrieves a value
* `store#[]=(key, value)` or `#set` or `#write` - stores a value
* `store#del(url)` - deletes a value

Even a plain Ruby hash will work, though it's not a great choice (cleared out when app is restarted, not shared between app instances, etc).

You can also set a custom prefix to be used for cache keys:

    Geocoder.configure(:cache_prefix => "...")

By default the prefix is `geocoder:`

If you need to expire cached content:

    Geocoder::Lookup.get(Geocoder.config[:lookup]).cache.expire(:all)  # expire cached results for current Lookup
    Geocoder::Lookup.get(:google).cache.expire("http://...")           # expire cached result for a specific URL
    Geocoder::Lookup.get(:google).cache.expire(:all)                   # expire cached results for Google Lookup
    # expire all cached results for all Lookups.
    # Be aware that this methods spawns a new Lookup object for each Service
    Geocoder::Lookup.all_services.each{|service| Geocoder::Lookup.get(service).cache.expire(:all)}

Do *not* include the prefix when passing a URL to be expired. Expiring `:all` will only expire keys with the configured prefix (won't kill every entry in your key/value store).

For an example of a cache store with URL expiry please see examples/autoexpire_cache.rb

_Before you implement caching in your app please be sure that doing so does not violate the Terms of Service for your geocoding service._


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/geocoder-olleh/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
