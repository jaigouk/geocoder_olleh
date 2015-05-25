$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'test/unit'
require 'coveralls'
Coveralls.wear!
require 'pry'
require 'geocoder/olleh'

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

    class Olleh
      private

      def default_fixture_filename
        "olleh_seoul"
      end
    end

  end
end

class GeocoderTestCase < Test::Unit::TestCase
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
