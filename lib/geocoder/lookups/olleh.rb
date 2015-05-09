require 'geocoder/lookups/base'
require "geocoder/results/olleh"
require 'base64'
require 'uri'
require 'json'
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

    def self.priority
      PRIORITY
    end

    def self.addrcdtype
      ADDR_CD_TYPES
    end

    def self.new_addr_types
      NEW_ADDR_TYPES
    end

    def self.include_jibun
      INCLUDE_JIBUN
    end

    def self.coord_types
      COORD_TYPES
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

    # need to be private. moved to public for testing
    # ----------------------------------------------
    def base_url(query)
      case check_query_type(query)
      when "route_search"
        "https://openapi.kt.com/maps/etc/RouteSearch?params="
      when "reverse_geocoding"
        "https://openapi.kt.com/maps/geocode/GetAddrByGeocode?params="
      else
        "https://openapi.kt.com/maps/geocode/GetGeocodeByAddr?params="
      end
    end


    def query_url_params(query)
      case check_query_type(query)
      when "route_search"
        JSON.generate({
          SX: query.options[:start_x],
          SY: query.options[:start_y],
          EX: query.options[:end_x],
          EY: query.options[:end_y],
          RPTYPE: "0",
          COORDTYPE: Olleh.coord_types[query.options[:coord_type]],
          PRIORITY: Olleh.priority[query.options[:priority]],
          timestamp:  Util.now
       })      
      when "reverse_geocoding"
        JSON.generate({
          x: query.text.first,
          y: query.text.last,
          addrcdtype: Olleh.addrcdtype[query.options[:addrcdtype]],
          newAddr: Olleh.new_addr_types[query.options[:new_addr_type]],
          isJibun: Olleh.include_jibun[query.options[:include_jibun]],
          timestamp: now
       })
      else
        JSON.generate({
          addr: URI.encode(query.sanitized_text),
          addrcdtype: Olleh.addrcdtype[query.options[:addrcdtype]],
          timestamp: now
        })
      end
    end

    def url_query_string(query)
      URI.encode(
        query_url_params(query)
      ).gsub(':','%3A').gsub(',','%2C').gsub('https%3A', 'https:')
    end  

    def check_query_type(query)
      if !query.options.blank? && query.options.include?(:priority)
        "route_search"
      elsif !query.options.blank? && query.options.include?(:include_jibun)
        "reverse_geocoding"
      else
        "geocoding"
      end
    end

    def make_api_request(query)
      timeout(configuration.timeout) do
        uri = URI.parse(query_url(query))
        Geocoder.log(:debug, "Geocoder: HTTP request being made for #{uri.to_s}")
        http_client.start(uri.host, uri.port, use_ssl: use_ssl?) do |client|
          req = Net::HTTP::Get.new(uri.request_uri, configuration.http_headers)
          if configuration.basic_auth[:user] and configuration.basic_auth[:password]
            req.basic_auth(
              configuration.basic_auth[:user],
              configuration.basic_auth[:password]
            )
          end
          client.request(req)
        end
      end
    end

  end
end