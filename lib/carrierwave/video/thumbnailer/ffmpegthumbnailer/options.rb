module CarrierWave
  module Video
    module Thumbnailer

      # Options to be be converted to CLI parameters
      class Options < Hash

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
          '--key'
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

        attr_reader :format, :options, :logger, :callbacks, :custom

        def initialize options
          @callbacks  = options.delete(:callbacks) || {}
          @custom     = options.delete  :custom
          @format     = options.delete  :format
          @logger     = options.delete  :logger
          @options    = Options.new     options
        end

        def to_cli
          %Q{#{"-c #{format} " if format}#{@options.to_cli}#{" #{custom}" if custom}}
        end

      end
    end
  end
end

