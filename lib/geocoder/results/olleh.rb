require 'geocoder/results/base'

module Geocoder::Result
  class Olleh < Base

    # NEED TO CHECK COORD SYSTEM
    # 
    def latitude
      coordinates[0].to_f
    end

    def longitude
      coordinates[1].to_f
    end

    def address
      @data['ADDRESS'].gsub('+', ' ')
    end

    def city
      @data['ADDRESS'].split('+').first
    end

    def gu
      @data['ADDRESS'].split('+')[1]
    end

    def dong
      @data['ADDRESS'].split('+')[2]
    end

    def dong_code
      @data['DONG_CODE']
    end

    alias_method :region, :country

    def state_code
      ""
    end

    alias_method :state, :state_code

    def country
      "South Korea"
    end

    alias_method :country_code, :country

    def postal_code
      ""
    end

    def coordinates
      [@data['X'], @data['Y']]
    end

    def address_data
      @data['ADDRESS']
    end

    def self.response_attributes
      %w[bbox name confidence entityType]
    end


    #########
    # methods for route search results
    def total_time
      @data[1]['ROUTE']['total_time']
    end

    def total_dist
      @data[1]['ROUTE']['total_dist']
    end

    def rg_cound
      @data[1]['ROUTE']['rg_count']
    end

    def rg_links
      @data[1]['ROUTE']['rg']
    end


    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end
