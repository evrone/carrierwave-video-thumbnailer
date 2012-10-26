require 'carrierwave/video/thumbnailer/version'
require 'carrierwave/video/thumbnailer/ffmpegthumbnailer'

module CarrierWave
  module Video
    module Thumbnailer
      extend ActiveSupport::Concern
      def self.ffmpegthumbnailer_binary=(bin)
        @ffmpegthumbnailer = bin
      end

      def self.ffmpegthumbnailer_binary
        @ffmpegthumbnailer.nil? ? 'ffmpegthumbnailer' : @ffmpegthumbnailer
      end
    end
  end
end
