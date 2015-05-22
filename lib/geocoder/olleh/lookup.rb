require 'geocoder'
module Geocoder
  module Lookup
    extend self

    ##
    # All street address lookup services, default first.
    #
    def street_services_with_olleh
      @street_services_with_olleh ||= [
        :dstk,
        :esri,
        :google,
        :google_premier,
        :google_places_details,
        :yahoo,
        :bing,
        :geocoder_ca,
        :geocoder_us,
        :yandex,
        :nominatim,
        :mapquest,
        :opencagedata,
        :ovi,
        :here,
        :baidu,
        :geocodio,
        :smarty_streets,
        :okf,
        :postcode_anywhere_uk,
        :olleh,
        :test
      ]
    end

    def all_services
      street_services_with_olleh + ip_services
    end

    def get(name)
      @services_with_olleh = {} unless defined? @services_with_olleh
      @services_with_olleh[name] = spawn(name) unless @services_with_olleh.include?(name)
      @services_with_olleh[name]
    end

    private # -----------------------------------------------------------------

    ##
    # Spawn a Lookup of the given name.
    #
    def spawn(name)
      if street_services_with_olleh.include?(name)
        Geocoder::Lookup.const_get(classify_name(name)).new
      else
        valids = street_services_with_olleh.map(&:inspect).join(", ")
        raise ConfigurationError, "Please specify a valid lookup for Geocoder " +
          "(#{name.inspect} is not one of: #{valids})."
      end
    end

  end
end