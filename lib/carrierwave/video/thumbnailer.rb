require 'carrierwave/video/thumbnailer/version'
require 'carrierwave/video/thumbnailer/ffmpegthumbnailer'

module CarrierWave
  module Video
    module Thumbnailer
      extend ActiveSupport::Concern

      module ClassMethods

        # Registers a thumbnailing processor
        def thumbnail format, options = {}
          process thumbnail: [format, options]
        end

      end

      def thumbnail format, opts = {}
        cache_stored_file! if !cached?

        @options = CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions.new(format, opts)
        tmp_path = File.join( File.dirname(current_path), "tmpfile.#{format}" )
        thumbnailer = ::FFMpegThumbnailer.new(current_path, tmp_path)

        with_callbacks do
          thumbnailer.run(@options)
          File.rename tmp_path, current_path
        end
      end

    end
  end
end
