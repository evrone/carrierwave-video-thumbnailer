require 'carrierwave/video/thumbnailer/version'
require 'carrierwave/video/thumbnailer/ffmpegthumbnailer'

module CarrierWave
  module Video
    module Thumbnailer
      extend ActiveSupport::Concern

      # Explicit class methods
      class << self

        # Sets a required thumbnailer binary
        def ffmpegthumbnailer_binary=(bin)
          @ffmpegthumbnailer = bin
        end

        # Tells the thumbnailer binary name
        def ffmpegthumbnailer_binary
          @ffmpegthumbnailer.nil? ? 'ffmpegthumbnailer' : @ffmpegthumbnailer
        end

      end


    end
  end
end
