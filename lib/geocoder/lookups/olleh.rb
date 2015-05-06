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

    def protocol
      "https"
    end

    def required_api_key_parts
      ["app_id", "app_key"]
    end

     # q = Geocoder::Query.new({ start_x: "952715", start_y: "1950203", end_x: "954643", end_y: "1951419", coord_type: 'wgs84', priority: 'shortest'})

    # "https://openapi.kt.com/maps/gen=4&searchtext=%7B%3Astart_x%3D%3E%22952715%22%2C+%3Astart_y%3D%3E%221950203%22%2C+%3Aend_x%3D%3E%22954643%22%2C+%3Aend_y%3D%3E%221951419%22%2C+%3Acoord_type%3D%3E%22wgs84%22%2C+%3Apriority%3D%3E%22shortest%22%7D"
    #
    #
    # TODO
    # NEED TO CHANGE RESULT. IT WILL TRAVERSE DATA
    #
    # CHANGE URL BASED ON QUERY
    #
    # PARSE "shortest" and change it for olleh map
    def url_query_string(query)
      hash_to_query(
        query_url_params(query).reject{ |key,value| value.nil? }
      )
    end

    def query_url(query)
      base_url(query) + url_query_string(query)
    end

    # )> Geocoder::Query.new("4.1.0.2", {street_address: true}).options
    # => {:street_address=>true}

    def base_url(query)
      if !query.options.blank? && query.options.include?(:priority)
        "https://openapi.kt.com/maps/etc/RouteSearch?"
      elsif !query.options.blank? && query.options.include?(:include_jibun)
        "https://openapi.kt.com/maps/geocode/GetAddrByGeocode?"
      else
        "https://openapi.kt.com/maps/geocode/GetGeocodeByAddr?"
      end
    end


    def api_key
      token
    end
    ##
    # Make an HTTP(S) request to a geocoding API and
    # return the response object.
    # https://github.com/augustl/net-http-cheat-sheet
    def make_api_request(query)
      timeout(configuration.timeout) do
        uri = URI.parse(query_url(query))
        Geocoder.log(:debug, "Geocoder: HTTP request being made for #{uri.to_s}")
        http_client.start(uri.host, uri.port, use_ssl: use_ssl?) do |client|
          req = Net::HTTP::Get.new(uri.request_uri, configuration.http_headers)
          req["Authorization"] = "Basic #{token}"
          client.request(req)
        end
      end
    end

    private # ---------------------------------------------------------------

    def results(query)
      return [] unless doc = fetch_data(query)
      return [] unless doc['Response'] && doc['Response']['View']
      if r=doc['Response']['View']
        return [] if r.nil? || !r.is_a?(Array) || r.empty?
        return r.first['Result']
      end
      []
    end

    # def query_url_params(query)

    #   if query.reverse_geocode?
    #     super.merge(options).merge(
    #       :prox=>query.sanitized_text,
    #       :mode=>:retrieveAddresses
    #     )
    #   else
    #     super.merge(options).merge(
    #       :searchtext=>query.sanitized_text
    #     )
    #   end
    # end

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