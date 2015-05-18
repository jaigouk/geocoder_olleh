require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'geocoder_olleh'

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

        if query.text.include? "삼성동"
          read_fixture "olleh_seoul"
        elsif query.text.include? "960713"
          read_fixture "olleh_reverse"
        elsif query.options.include?(:coord_in)
          read_fixture "olleh_convert_coord"
        elsif query.options.include?(:priority)
          read_fixture "olleh_routes"
        elsif query.options.include?(:l_code)
          read_fixture "olleh_addr_step_search"
        elsif query.options.include?(:radius)
          read_fixture "olleh_nearest_position_search"
        else
          read_fixture fixture_for_query(query)
        end
      end
    end
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
