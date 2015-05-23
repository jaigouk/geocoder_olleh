$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'coveralls'
Coveralls.wear!
require 'pry'
require_relative '../lib/geocoder/olleh'
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'yaml'
configs = YAML.load_file('test/database.yml')

if configs.keys.include? ENV['DB']
  require 'active_record'

  # Establish a database connection
  ActiveRecord::Base.configurations = configs

  db_name = ENV['DB']
  ActiveRecord::Base.establish_connection(db_name)
  ActiveRecord::Base.default_timezone = :utc

  ActiveRecord::Migrator.migrate('test/db/migrate', nil)
else
  class MysqlConnection
    def adapter_name
      "mysql"
    end
  end

  ##
  # Simulate enough of ActiveRecord::Base that objects can be used for testing.
  #
  module ActiveRecord
    class Base

      def initialize
        @attributes = {}
      end

      def read_attribute(attr_name)
        @attributes[attr_name.to_sym]
      end

      def write_attribute(attr_name, value)
        @attributes[attr_name.to_sym] = value
      end

      def update_attribute(attr_name, value)
        write_attribute(attr_name.to_sym, value)
      end

      def self.scope(*args); end

      def self.connection
        MysqlConnection.new
      end

      def method_missing(name, *args, &block)
        if name.to_s[-1..-1] == "="
          write_attribute name.to_s[0...-1], *args
        else
          read_attribute name
        end
      end

      class << self
        def table_name
          'test_table_name'
        end

        def primary_key
          :id
        end
      end
    end
  end
end

# simulate Rails module so Railtie gets loaded
module Rails
end

# Require Geocoder after ActiveRecord simulator.
require 'geocoder'
require 'geocoder/lookups/base'
require 'geocoder/railtie'
# and initialize Railtie manually (since Rails::Railtie doesn't exist)
Geocoder::Railtie.insert

##
# Mock HTTP request to geocoding service.
#
module Geocoder
  module Lookup
    class Base
      private

      def fixture_exists?(filename)
        File.exist?(File.join("test", "fixtures", filename))
      end

      def read_fixture(file)
        filepath = File.join("test", "fixtures", file)
        s = File.read(filepath).strip.gsub(/\n\s*/, "")
        MockHttpResponse.new(body: s, code: "200")
      end

      ##
      # Fixture to use if none match the given query.
      #
      def default_fixture_filename
        "#{fixture_prefix}_madison_square_garden"
      end

      def fixture_prefix
        handle
      end

      def fixture_for_query(query)
        label = query.reverse_geocode? ? "reverse" : query.text.gsub(/[ \.]/, "_")
        filename = "#{fixture_prefix}_#{label}"
        fixture_exists?(filename) ? filename : default_fixture_filename
      end

      remove_method(:make_api_request)

      def make_api_request(query)
        return raise TimeoutError if query.text == "timeout"
        return raise SocketError if query.text == "socket_error"
        return raise Errno::ECONNREFUSED if query.text == "connection_refused"
        if query.text == "invalid_json"
          return MockHttpResponse.new(:body => 'invalid json', :code => 200)
        end
        read_fixture fixture_for_query(query)
      end
    end


    class Olleh
      private
      def fixture_prefix
        "olleh"
      end
      def default_fixture_filename
        "olleh_seoul"
      end
      remove_method(:make_api_request)

      def make_api_request(query)
        return raise TimeoutError if query.text == "timeout"
        return raise SocketError if query.text == "socket_error"
        return raise Errno::ECONNREFUSED if query.text == "connection_refused"
        if query.text == "invalid_json"
          return MockHttpResponse.new(:body => 'invalid json', :code => 200)
        end

        if query.options.include?(:vx1)
          read_fixture "olleh_waypoints"
        elsif query.options.include?(:priority)
          read_fixture "olleh_routes"
        elsif query.options.include?(:coord_in)
          read_fixture "olleh_convert_coordinates"
        elsif query.options.include?(:l_code)
          read_fixture "olleh_addr_step_search"
        elsif query.options.include?(:radius)
          read_fixture "olleh_nearest_position_search"
        elsif query.text.include?("960713") && !query.options.include?(:coord_in)
          read_fixture "olleh_reverse"
        elsif query.text.include? "삼성동"
          read_fixture "olleh_seoul"
        else
          read_fixture fixture_for_query(query)
        end
      end
    end



  end
end

##
# Geocoded model.
#
class Place < ActiveRecord::Base
  geocoded_by :address

  def initialize(name, address)
    super()
    write_attribute :name, name
    write_attribute :address, address
  end
end

##
# Geocoded model.
# - Has user-defined primary key (not just 'id')
#
class PlaceWithCustomPrimaryKey < Place

  class << self
    def primary_key
      :custom_primary_key_id
    end
  end

end

class PlaceReverseGeocoded < ActiveRecord::Base
  reverse_geocoded_by :latitude, :longitude

  def initialize(name, latitude, longitude)
    super()
    write_attribute :name, name
    write_attribute :latitude, latitude
    write_attribute :longitude, longitude
  end
end

class PlaceWithCustomResultsHandling < ActiveRecord::Base
  geocoded_by :address do |obj,results|
    if result = results.first
      obj.coords_string = "#{result.latitude},#{result.longitude}"
    else
      obj.coords_string = "NOT FOUND"
    end
  end

  def initialize(name, address)
    super()
    write_attribute :name, name
    write_attribute :address, address
  end
end

class PlaceReverseGeocodedWithCustomResultsHandling < ActiveRecord::Base
  reverse_geocoded_by :latitude, :longitude do |obj,results|
    if result = results.first
      obj.country = result.country_code
    end
  end

  def initialize(name, latitude, longitude)
    super()
    write_attribute :name, name
    write_attribute :latitude, latitude
    write_attribute :longitude, longitude
  end
end

class PlaceWithForwardAndReverseGeocoding < ActiveRecord::Base
  geocoded_by :address, :latitude => :lat, :longitude => :lon
  reverse_geocoded_by :lat, :lon, :address => :location

  def initialize(name)
    super()
    write_attribute :name, name
  end
end

class PlaceWithCustomLookup < ActiveRecord::Base
  geocoded_by :address, :lookup => :nominatim do |obj,results|
    if result = results.first
      obj.result_class = result.class
    end
  end

  def initialize(name, address)
    super()
    write_attribute :name, name
    write_attribute :address, address
  end
end

class PlaceWithCustomLookupProc < ActiveRecord::Base
  geocoded_by :address, :lookup => lambda{|obj| obj.custom_lookup } do |obj,results|
    if result = results.first
      obj.result_class = result.class
    end
  end

  def custom_lookup
    :nominatim
  end

  def initialize(name, address)
    super()
    write_attribute :name, name
    write_attribute :address, address
  end
end

class PlaceReverseGeocodedWithCustomLookup < ActiveRecord::Base
  reverse_geocoded_by :latitude, :longitude, :lookup => :nominatim do |obj,results|
    if result = results.first
      obj.result_class = result.class
    end
  end

  def initialize(name, latitude, longitude)
    super()
    write_attribute :name, name
    write_attribute :latitude, latitude
    write_attribute :longitude, longitude
  end
end


class GeocoderTestCase < Test::Unit::TestCase

  def setup
    super
    Geocoder::Configuration.instance.set_defaults
    Geocoder.configure(
      :maxmind => {:service => :city_isp_org},
      :maxmind_geoip2 => {:service => :insights, :basic_auth => {:user => "user", :password => "password"}})
  end

  def geocoded_object_params(abbrev)
    {
      :msg => ["Madison Square Garden", "4 Penn Plaza, New York, NY"]
    }[abbrev]
  end

  def reverse_geocoded_object_params(abbrev)
    {
      :msg => ["Madison Square Garden", 40.750354, -73.993371]
    }[abbrev]
  end

  def set_api_key!(lookup_name)
    lookup = Geocoder::Lookup.get(lookup_name)
    if lookup.required_api_key_parts.size == 1
      key = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    elsif lookup.required_api_key_parts.size > 1
      key = lookup.required_api_key_parts
    else
      key = nil
    end
    Geocoder.configure(:api_key => key)
  end
end

class MockHttpResponse
  attr_reader :code, :body
  def initialize(options = {})
    @code = options[:code].to_s
    @body = options[:body]
    @headers = options[:headers] || {}
  end

  def [](key)
    @headers[key]
  end
end
