module CarrierWave
  module Video
    module Thumbnailer

      # Settings to be be converted to CLI parameters
      class Setting < Hash

        def initialize opts
          opts.each { |k, v| self[k] = v}
        end

        def to_cli
          self.map do |k, v|
            "#{cli_key k} #{cli_val v}"
          end.join(' ')
        end

        private

        def cli_key k
          case k
          when :format  then '-c'
          when :options then self[k].each { |key, val| "#{cli_key key} #{cli_val val}" } if self[k] and not self[k].empty?
          else ''
          end
        end

        def cli_val v
          if v
            v.empty? ? '' : v.to_s
          else
            ''
          end
        end

      end

      class FFMpegThumbnailerOptions

        attr_reader :format, :options, :logger

        def initialize format, options
          @format   = Setting.new format:   format
          @logger   = options.delete :logger
          @options  = Setting.new options:  options
        end

        def to_cli
          @options.to_cli
        end

      end
    end
  end
end

