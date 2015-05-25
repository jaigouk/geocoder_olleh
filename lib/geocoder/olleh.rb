require 'geocoder'
require 'geocoder/lookups/olleh'
require 'geocoder/results/olleh'
require 'geocoder/olleh/version'

module Geocoder
  module Olleh
  end
end

Geocoder::Lookup.street_services << :olleh