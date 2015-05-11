require 'geocoder/lookups/base'
require "geocoder/results/olleh"
require 'base64'
require 'uri'
require 'json'
module Geocoder::Lookup
  ##
  # Route Search
  # shortest : ignore traffic. shortest path
  # high way : include high way 
  # free way : no charge
  # optimal  : based on traffic
  class Olleh < Base


    PRIORITY = {
      'shortest' => 0, # 최단거리 우선 
      'high_way' => 1, # 고속도로 우선 
      'free_way' => 2, # 무료도로 우선 
      'optimal'  => 3  # 최적경로 
    }

    ADDR_CD_TYPES = {
      'law'            => 0, # 법정동 
      'administration' => 1, # 행정동
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

    def initialize
      super
      Geocoder.configure(
        :use_https => true,
        :http_headers => {"Authorization" => "Basic #{token}"}
      )
    end

    def name
      "Olleh"
    end

    def required_api_key_parts
      ["app_id", "app_key"]
    end

    def query_url(query)
      base_url(query) + url_query_string(query)
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
    
    def auth_key
      token
    end


    private # ----------------------------------------------

    # results goes through structure and check returned hash.
    def results(query)
      data = fetch_data(query)
      return [] unless data
      doc = JSON.parse(URI.decode(data["payload"]))

      if doc['ERRCD'] != 0
        Geocoder.log(:warn, "Olleh API error: #{doc['ERRCD']} (#{doc['ERRMS'].gsub('+', ' ')}).")
        return [] 
      end

      # GEOCODING / REVERSE GECOCODING      
      if doc['RESDATA']['COUNT']
        return [] if doc['RESDATA']['COUNT'] == 0
        return doc['RESDATA']["ADDRS"]
        
      # ROUTE SEARCH
      elsif doc["RESDATA"]["SROUTE"] && doc["RESDATA"]["SROUTE"]["isRoute"]        
        return [] if doc["RESDATA"]["SROUTE"]["isRoute"] == "false"
        return doc["RESDATA"]
      else
        []
      end
    end      
    


    def make_api_request(query)
      timeout(configuration.timeout) do
        uri = URI.parse(query_url(query))
        Geocoder.log(:debug, "Geocoder: HTTP request being made for #{uri.to_s}")
        http_client.start(uri.host, uri.port, use_ssl: use_ssl?) do |client|
          req = Net::HTTP::Get.new(uri.request_uri, configuration.http_headers)
          
          client.request(req)
        end
      end
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

    def base_url(query)
      case check_query_type(query)
      when "route_search"
        "https://openapi.kt.com/maps/etc/RouteSearch?params="
      when "reverse_geocoding"
        "https://openapi.kt.com/maps/geocode/GetAddrByGeocode?params="
      when "convert_coord"
        "https://openapi.kt.com/maps/etc/ConvertCoord?params="
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
          COORDTYPE: Olleh.coord_types[query.options[:coord_type]] || 7,
          PRIORITY: Olleh.priority[query.options[:priority]],
          timestamp:  now
       })      
      when "convert_coord"
        JSON.generate({
          x: query.text.first,
          y: query.text.last,
          inCoordType: self.coord_types[options[:coord_in]],
          outCoordType: self.coord_types[options[:coord_out]],
          timestamp: now
       })
      when "reverse_geocoding"
        JSON.generate({
          x: query.text.first,
          y: query.text.last,
          addrcdtype: Olleh.addrcdtype[query.options[:addrcdtype]] || 0,
          newAddr: Olleh.new_addr_types[query.options[:new_addr_type]] || 0,
          isJibun: Olleh.include_jibun[query.options[:include_jibun]] || 0,
          timestamp: now
       })
      else # geocoding
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
      elsif query.reverse_geocode?
        "reverse_geocoding"
      elsif !query.options.blank? && query.options.include?(:coord_in)
        "convert_coord"
      else
        "geocoding"
      end
    end

   

  end
end