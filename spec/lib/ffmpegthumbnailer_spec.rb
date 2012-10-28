require 'spec_helper'
require 'carrierwave/video/thumbnailer'

describe CarrierWave::Video::Thumbnailer::FFMpegThumbnailer do

  describe "#run" do
    let(:input_file_path) { '/tmp/file.mov' }
    let(:output_file_path) { '/tmp/file.jpg' }
    let(:binary) { 'thumbnailrrr' }

    let(:thumbnailer) { CarrierWave::Video::Thumbnailer::FFMpegThumbnailer.new(input_file_path, output_file_path) }

    before do
      CarrierWave::Video::Thumbnailer::FFMpegThumbnailer.binary = binary
    end

    it "should run the ffmpegthumbnailer binary" do
      @options = CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions.new({})
      command = "#{binary} -i #{input_file_path} -o #{output_file_path}"
      Open3.should_receive(:popen3).with(command)

      thumbnailer.run @options
    end

    context "with full set of CLI options" do

      it "runs the thumbnailer with all corresponding CLI keys" do

        opts = {
          format:     'png',
          size:       '512',
          seek:       '20%',
          quality:    10,
          square:     true,
          strip:      true,
          workaround: true,
          custom:     '-v'
        }

        @options = CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions.new opts

        cli = "#{binary} -i #{input_file_path} -o #{output_file_path} -c png -s 512 -t 20% -q 10 -a -f -w -v"
        Open3.should_receive(:popen3).with(cli)

        thumbnailer.run @options
      end

    end

    context "given a logger" do
      let(:logger) { mock(:logger) }

      it "should run and log results" do
        @options = CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions.new({logger: logger})
        command = "#{binary} -i #{input_file_path} -o #{output_file_path}"
        Open3.should_receive(:popen3).with(command)
        logger.should_receive(:info).with("Running....#{command}")
        logger.should_receive(:error).with("Failure!")

        thumbnailer.run @options
      end
    end
  end
end


