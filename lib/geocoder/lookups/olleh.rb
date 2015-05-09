require 'geocoder/lookups/base'
require "geocoder/results/olleh"
require 'base64'

module Geocoder::Lookup
  class Olleh < Base

    PRIORITY = {
      'shortest' => 0,
      'high_way' => 1,
      'free_way' => 2,
      'optimal'  => 3
    }

    ADDR_CD_TYPES = {
      'law'            => 0,
      'administration' => 1,
      'law_and_admin'  => 2,
      'road'           => 3
    }

    NEW_ADDR_TYPES = {
      'old'     => 0,
      'new'     => 1
    }

    INCLUDE_JIBUN = {
      'no'      => 0,
      'yes'     => 1
    }

    COORD_TYPES = {
      'utmk'    => 0,
      'tm_west' => 1,
      'tm_mid'  => 2,
      'tm_east' => 3,
      'katec'   => 4,
      'utm52'   => 5,
      'utm51'   => 6,
      'wgs84'   => 7,
      'bessel'  => 8
    }

    def name
      "Olleh"
    end

    def required_api_key_parts
      ["app_id", "app_key"]
    end

    def query_url(query)
      base_url(query) + url_query_string(query)
    end

    def api_key
      token
    end


    private # ----------------------------------------------

    # results goes through structure and check returned hash.
    def results(query)
      doc = fetch_data(query)

      return [] unless doc
      if doc['statusCode'] == 200
        return doc['resourceSets'].first['estimatedTotal'] > 0 ? doc['resourceSets'].first['resources'] : []
      elsif doc['statusCode'] == 401 and doc["authenticationResultCode"] == "InvalidCredentials"
        raise_error(Geocoder::InvalidApiKey) || Geocoder.log(:warn, "Invalid Bing API key.")
      else
        Geocoder.log(:warn, "Bing Geocoding API error: #{doc['statusCode']} (#{doc['statusDescription']}).")
      end
      return doc

    end

    def base_url(query)
      if !query.options.blank? && query.options.include?(:priority)
        "https://openapi.kt.com/maps/etc/RouteSearch?"
      elsif !query.options.blank? && query.options.include?(:include_jibun)
        "https://openapi.kt.com/maps/geocode/GetAddrByGeocode?"
      else
        "https://openapi.kt.com/maps/geocode/GetGeocodeByAddr?"
      end
    end


    def query_url_params(query)
      {
        (query.reverse_geocode? ? :location : :address) => query.sanitized_text,
        :ak => configuration.api_key,
        :output => "json"
      }.merge(super)
    end

    def url_query_string(query)
      hash_to_query(
        query_url_params(query).reject{ |key,value| value.nil? }
      )
    end    


    def token
      if a = configuration.api_key
        if a.is_a?(Array)
          return  Base64.encode64("#{a.first}:#{a.last}").strip
        end
      end
    end

    def now
      Time.now.strftime("%Y%m%d%H%M%S%L")
    end

  end
end