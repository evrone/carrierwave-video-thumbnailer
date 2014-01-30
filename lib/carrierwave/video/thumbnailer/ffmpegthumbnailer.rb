require 'carrierwave/video/thumbnailer/ffmpegthumbnailer/options'
require 'open3'

module CarrierWave
  module Video
    module Thumbnailer
      class FFMpegThumbnailer

        # Explicit class methods
        class << self

          # Sets a required thumbnailer binary
          def binary=(bin)
            @ffmpegthumbnailer = bin
          end

          # Tells the thumbnailer binary name
          def binary
            @ffmpegthumbnailer.nil? ? 'ffmpegthumbnailer' : @ffmpegthumbnailer
          end

          def logger= log
            @logger = log
          end

          def logger
            return @logger if @logger
            logger = Logger.new(STDOUT)
            logger.level = Logger::INFO
            @logger = logger
          end

        end

        attr_reader :input_path, :output_path

        def initialize in_path, out_path
          @input_path  = in_path
          @output_path = out_path
        end

        def run options
          logger = options.logger
          cmd = %Q{#{CarrierWave::Video::Thumbnailer::FFMpegThumbnailer.binary} -i "#{input_path}" -o "#{output_path}" #{options.to_cli}}.rstrip

            logger.info("Running....#{cmd}") if logger
            outputs = []
            exit_code = nil

            Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
              stderr.each("r") do |line|
                outputs << line
              end
              exit_code = wait_thr.value
            end

            handle_exit_code(exit_code, outputs, logger)
        end

        private

        def handle_exit_code(exit_code, outputs, logger)
          return unless logger
          if exit_code == 0
            logger.info("Success!")
          else
            outputs.each do |output|
              logger.error(output)
            end
            logger.error("Failure!")
          end
          exit_code
        end

      end
    end
  end
end
