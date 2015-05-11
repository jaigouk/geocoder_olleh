# encoding: utf-8
require 'test_helper'

class OllehTest < GeocoderTestCase

  def setup
    Geocoder.configure(lookup: :olleh, :api_key => ["OllehMapAPI0100", "bncT89dfRT"])
  end

  def test_olleh_api_key
    g = Geocoder::Lookup::Olleh.new
    assert_match "T2xsZWhNYXBBUEkwMTAwOmJuY1Q4OWRmUlQ=", g.auth_key
  end

  def test_request_header_for_geocode
    lookup = Geocoder::Lookup::Olleh.new    
    assert Geocoder.config.http_headers[:Authorization] == "Basic T2xsZWhNYXBBUEkwMTAwOmJuY1Q4OWRmUlQ="
  end

  def test_query_for_geocode
    lookup = Geocoder::Lookup::Olleh.new
    url = lookup.query_url(Geocoder::Query.new("서울특별시 강남구 삼성동 168-1"))
    assert url.include?("addr%22%3A%22%25EC%2584%259C%25EC%259A%25B8%25ED%258A%25B9%25EB%25B3%2584%25EC%258B%259C%2520%25EA%25B0%2595%25EB%2582%25A8%25EA%25B5%25AC%2520%25EC%2582%25BC%25EC%2584%25B1%25EB%258F%2599%2520168-1%22"), "Invalide address parsing"
  end

  def test_query_for_geocode_address_code_type
    lookup = Geocoder::Lookup::Olleh.new
    url = lookup.query_url(Geocoder::Query.new("서울특별시 강남구 삼성동 168-1", {addrcdtype: 'law'}))
    assert url.include?("addrcdtype%22%3A0%2C"), "Invalide address parsing"
  end

  def test_cached
    query = Geocoder::Query.new("서울특별시 강남구 삼성동 168-1")
    # require 'pry'
    # binding.pry
  end

  def test_check_query_type
    
  end

  # def test_google_result_components
  #   result = Geocoder.search("Madison Square Garden, New York, NY").first
  #   assert_equal "Manhattan",
  #     result.address_components_of_type(:sublocality).first['long_name']
  # end
end