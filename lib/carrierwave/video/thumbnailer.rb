require 'carrierwave'
require 'carrierwave/video/thumbnailer/version'
require 'carrierwave/video/thumbnailer/ffmpegthumbnailer'

module CarrierWave
  module Video
    module Thumbnailer
      extend ActiveSupport::Concern

      module ClassMethods

        def thumbnail options = {}
          process thumbnail: options
        end

      end

      def thumbnail opts = {}
        cache_stored_file! if !cached?

        @options = CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions.new(opts)
        format = @options.format || 'jpg'

        tmp_path = File.join( File.dirname(current_path), "tmpfile.#{format}" )
        thumbnailer = FFMpegThumbnailer.new(current_path, tmp_path)

        with_thumbnailing_callbacks do
          thumbnailer.run(@options)
          File.rename tmp_path, current_path
        end
      end

      private

      def with_thumbnailing_callbacks(&block)
        callbacks = @options.callbacks
        logger = @options.logger
        begin
          send_thumbnailing_callback(callbacks[:before_thumbnail])
          setup_thumbnailing_logger
          block.call
          send_thumbnailing_callback(callbacks[:after_thumbnail])
        rescue => e
          send_thumbnailing_callback(callbacks[:rescue])

          if logger
            logger.error "#{e.class}: #{e.message}"
            e.backtrace.each do |b|
              logger.error b
            end
          end

          raise CarrierWave::ProcessingError.new("Failed to thumbnail with ffmpegthumbnailer. Check ffmpegthumbnailer install and verify video is not corrupt. Original error: #{e}")
        ensure
          reset_thumbnailing_logger
          send_thumbnailing_callback(callbacks[:ensure])
        end
      end

      def send_thumbnailing_callback(callback)
        model.send(callback, @options) if callback.present?
      end

      def setup_thumbnailing_logger
        return unless @options.logger.present?
        @ffmpegthumbnailer_logger = FFMpegThumbnailer.logger
        FFMpegThumbnailer.logger = @options.logger
      end

      def reset_thumbnailing_logger
        return unless @ffmpegthumbnailer_logger
        FFMpegThumbnailer.logger = @ffmpegthumbnailer_logger
      end

    end
  end
end
