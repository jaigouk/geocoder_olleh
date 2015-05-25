# encoding: utf-8
require 'test_helper'

class OllehTest < GeocoderTestCase

  def setup
    Geocoder.configure(lookup: :olleh, olleh: {
      basic_auth: {
        user: 'OllehMapAPI0100',
        password: 'bncT89dfRT'
      }
    })
  end

  def test_query_for_geocode
    lookup = Geocoder::Lookup::Olleh.new
    url = lookup.query_url(Geocoder::Query.new('서울특별시 강남구 삼성동 168-1'))
    assert url.include?('addr%22%3A%22%25EC%2584%259C%25EC%259A%25B8%25ED%258A%25B9%25EB%25B3%2584%25EC%258B%259C%2520%25EA%25B0%2595%25EB%2582%25A8%25EA%25B5%25AC%2520%25EC%2582%25BC%25EC%2584%25B1%25EB%258F%2599%2520168-1%22'), "Invalide address parsing"
  end

  def test_query_for_geocode_address_code_type
    lookup = Geocoder::Lookup::Olleh.new
    url = lookup.query_url(Geocoder::Query.new('서울특별시 강남구 삼성동 168-1', {addrcdtype: 'law'}))
    assert url.include?('addrcdtype%22%3A0%2C'), 'Invalide address parsing'
  end

  def test_gecode_with_options
    query = Geocoder::Query.new('삼성동',{:addrcdtype => 'law'})
    lookup = Geocoder::Lookup::Olleh.new
    url_with_params = lookup.query_url(query)
    assert url_with_params.include? '%22addrcdtype%22%3A0%2C%22'
  end

  def test_check_query_type
    query = Geocoder::Query.new('삼성동',{:addrcdtype => 'law'})
    lookup = Geocoder::Lookup::Olleh.new
    assert lookup.search(query).count == 2
  end

  def test_olleh_result_components
    query = Geocoder::Query.new('삼성동',{:addrcdtype => 'law'})

    lookup = Geocoder::Lookup::Olleh.new
    result = lookup.search(query).first
    assert result.address == '서울특별시 강남구 삼성동'
    assert result.country == 'South Korea'
    assert result.city == '서울특별시'
    assert result.gu == '강남구'

    assert result.dong == '삼성동'
    assert result.dong_code == '1168010500'
    assert result.coordinates == [960713, 1946274]
  end


  def test_olleh_geocoding_no_result
    query = Geocoder::Query.new('no results',{:addrcdtype => 'law'})
    lookup = Geocoder::Lookup::Olleh.new
    assert lookup.search(query) == []
  end

  def test_olleh_reverse_geocoding
    query = Geocoder::Query.new([960713, 1946274],{addrcdtype: 'law', newAddr: 'new', isJibun: 'yes'})
    lookup = Geocoder::Lookup::Olleh.new
    result = lookup.search(query).first
    assert result.address == '서울특별시 강남구 삼성동 74-14'
  end

  def test_olleh_route_searching
    query = Geocoder::Query.new(
      '', {
      start_x: 960713,
      start_y: 1946274,
      end_x: 950000,
      end_y: 1940594,
      priority: 'shortest',
      coord_type: 'wgs84'
    })
    lookup = Geocoder::Lookup::Olleh.new
    result = lookup.search(query).first
    assert result.total_dist == '15714'
    assert result.total_time == '42.2'
  end

  def test_olleh_convert_coord
    query = Geocoder::Query.new(
      [951203, 1950435], {
      coord_in: 'utmk',
      coord_out: 'wgs84'
    })
    lookup = Geocoder::Lookup::Olleh.new
    result = lookup.search(query).first
    assert result.coord_type == 'LLW'
    assert result.converted_coord == ['126.9475548915227', '37.551966221235176']
  end

  def test_olleh_addr_step_search
    query = Geocoder::Query.new('', {l_code: 11})
    lookup = Geocoder::Lookup::Olleh.new
    result = lookup.search(query).first
    assert result.addr_step_sido == '서울특별시'
    assert result.addr_step_sigungu == '종로구'
    assert result.addr_step_l_code == '11110'
    assert result.coordinates == ['954050', '1952755']
    assert result.addr_step_p_code == '009000023000000'
  end

  def test_olleh_result_wgs_coordinates
    query = Geocoder::Query.new('', {l_code: 11})
    lookup = Geocoder::Lookup::Olleh.new
    result = lookup.search(query).first
    assert result.coordinates == ['954050', '1952755']
    assert result.wgs_coordinates == ['126.9475548915227', '37.551966221235176']
  end

  def test_olleh_addr_nearest_position_search
    query = Geocoder::Query.new(
      '', {
      px: 966759,
      py: 1947935,
      radius: 100
    })
    lookup = Geocoder::Lookup::Olleh.new
    result = lookup.search(query).first
    assert result.position_address == "서울특별시 강동구 성내동 540"
  end

end
