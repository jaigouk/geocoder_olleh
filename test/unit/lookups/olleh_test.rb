# encoding: utf-8
require 'test_helper'

class OllehTest < GeocoderTestCase

  def setup
    Geocoder.configure(lookup: :olleh)
    set_api_key!(:olleh)
    #     require 'pry'
    # binding.pry
  end

    def test_query_for_reverse_geocode
    lookup = Geocoder::Lookup::Olleh.new
    # url = lookup.query_url(Geocoder::Query.new([45.423733, -75.676333]))

    # assert_match(/Locations\/45.423733/, url)
  end
end