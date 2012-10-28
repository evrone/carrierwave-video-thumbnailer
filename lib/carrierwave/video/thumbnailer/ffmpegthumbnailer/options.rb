module CarrierWave
  module Video
    module Thumbnailer

      # Options to be be converted to CLI parameters
      class Options < Hash

        BOOLEAN = [
          :square,
          :strip,
          :workaround
        ]

        def initialize opts
          opts.each { |k, v| self[k] = v}
        end

        def to_cli
          self.map do |k, v|
            if BOOLEAN.include? k
              cli_key k if v
            else
              "#{cli_key k} #{cli_val v}"
            end
          end.join(' ')
        end

        private

        def cli_key k
          '-' + (
                  case k
                  when :size        then 's'
                  when :seek        then 't'
                  when :quality     then 'q'
                  when :square      then 'a'
                  when :strip       then 'f'
                  when :workaround  then 'w'
                  else
                    '-noop'
                  end
          )
        end

        def cli_val v
            v.to_s
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

