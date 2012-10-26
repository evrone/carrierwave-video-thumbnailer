require 'spec_helper'
require 'carrierwave/video/thumbnailer'

describe Carrierwave::Video::Thumbnailer do
  class Thumbnailer; end

  class TestVideoThumbnailer
    include CarrierWave::Video::Thumbnailer
    def cached?; end
    def cache_stored_file!; end
    def model
      @thumbnailer ||= Thumbnailer.new
    end
  end

  let(:thumbnailer) { TestVideoThumbnailer.new }

  describe "::thumbnail" do
    it "processes the model" do
      TestVideoThumbnailer.should_receive(:process).with(thumbnail: :opts)
      TestVideoThumbnailer.thumbnail(:opts)
    end

    it "does not require options" do
      TestVideoThumbnailer.should_receive(:process).with(thumbnail: {})
      TestVideoThumbnailer.thumbnail
    end
  end

  describe "#thumbnail" do
    let(:format) { 'jpg' }
    let(:movie) { mock }

    before do
      thumbnailer.stub(:current_path).and_return('video/path/file.mov')

      CarrierWave::Video::Thumbnailer::FFMpegThumbnailer.should_receive(:new).and_return(movie)
    end

    context "with no options set" do
      before {  File.should_receive(:rename) }

      it "calls transcode with correct format options" do
        movie.should_receive(:thumbnail) do |path, opts, format_opts|
          expect(format_opts).to eq({format: :jpg})
          expect(opts[:format]).to eq 'jpg'
          expect(path).to eq "video/path/tmpfile.#{format}"
        end

        thumbnailer.thumbnail(format)
      end
    end

    context "with callbacks set" do
      before { movie.should_receive(:thumbnail) }
      let(:opts) do
        {
          callbacks: {
            before_thumbnail: :method1,
            after_thumbnail:  :method2,
            rescue:           :method3,
            ensure:           :method4
          }
        }
      end

      context "no exceptions raised" do
        before {  File.should_receive(:rename) }

        it "calls before_thumbnail, after_thumbnail, and ensure" do
          thumbnailer.model.should_receive(:method1).with(format, opts).ordered
          thumbnailer.model.should_receive(:method2).with(format, opts).ordered
          thumbnailer.model.should_not_receive(:method3)
          thumbnailer.model.should_receive(:method4).with(format, opts).ordered

          thumbnailer.thumbnail(format, opts)
        end
      end

      context "exception raised" do
        let(:e) { StandardError.new("test error") }
        before { File.should_receive(:rename).and_raise(e) }


        it "calls before_thumbnail and ensure" do
          thumbnailer.model.should_receive(:method1).with(format, opts).ordered
          thumbnailer.model.should_not_receive(:method2)
          thumbnailer.model.should_receive(:method3).with(format, opts).ordered
          thumbnailer.model.should_receive(:method4).with(format, opts).ordered

          lambda do
            thumbnailer.thumbnail(format, opts)
          end.should raise_exception(CarrierWave::ProcessingError)
        end
      end
    end

    context "with logger set" do
      let(:logger) { mock }
      before do
        thumbnailer.model.stub(:logger).and_return(logger)
        movie.should_receive(:transcode)
      end

      context "with no exceptions" do
        before { File.should_receive(:rename) }

        it "sets FFMpegThumbnailer logger to logger and resets" do
          old_logger = ::FFMpegThumbnailer.logger
          ::FFMpegThumbnailer.should_receive(:logger=).with(logger).ordered
          ::FFMpegThumbnailer.should_receive(:logger=).with(old_logger).ordered
          thumbnailer.thumbnail(format, logger: :logger)
        end
      end

      context "with exceptions" do
        let(:e) { StandardError.new("test error") }
        before { File.should_receive(:rename).and_raise(e) }

        it "logs exception" do
          logger.should_receive(:error).with("#{e.class}: #{e.message}")
          logger.should_receive(:error).any_number_of_times  # backtrace

          lambda do
            thumbnailer.thumbnail(format, logger: :logger)
          end.should raise_exception(CarrierWave::ProcessingError)
        end
      end
    end

    context "with custom passed in" do
      before do
        File.should_receive(:rename)
      end

      it "takes the provided custom param" do
        movie.should_receive(:thumbnail) do |path, opts, format_opts|
          opts[:custom].should eq '-s 256'
        end

        thumbnailer.thumbnail(format, custom: '-s 256')
      end
    end

    ##
    # NEXT WORKDAY :)
    #

    # context "given a block" do
    #   let(:movie) { mock }
    #   let(:opts) { {} }
    #   let(:params) { { resolution: "640x360", watermark: {}, video_codec: "libvpx", audio_codec: "libvorbis", custom: "-b 1500k -ab 160000 -f webm -g 30" } }

    #   before do
    #     File.should_receive(:rename)
    #     movie.stub(:resolution).and_return('1280x720')
    #   end

    #   it "calls the block, with the movie file and params" do
    #     movie.should_receive(:transcode) do |path, format_opts, codec_opts|
    #       format_opts[:video_codec].should == 'libvpx'
    #       format_opts[:audio_codec].should == 'libvorbis'
    #     end

    #     expect {
    #       |block| thumbnailer.thumbnail(format, opts, &block)
    #     }.to yield_with_args(movie, params)
    #   end

    #   it "allows the block to modify the params" do
    #     block = Proc.new { |input, params| params[:custom] = '-preset slow' }

    #     movie.should_receive(:transcode) do |path, format_opts, codec_opts|
    #       format_opts[:custom].should == '-preset slow'
    #     end

    #     thumbnailer.thumbnail(format, opts, &block)
    #   end

    #   it "evaluates the final params after any modifications" do
    #     block = Proc.new do |input, params|
    #       params[:custom] = '-preset slow'
    #       params[:watermark][:path] = 'customized/path'
    #     end

    #     movie.should_receive(:transcode) do |path, format_opts, codec_opts|
    #       format_opts[:custom].should == '-preset slow -vf "movie=customized/path [logo]; [in][logo] overlay= [out]"'
    #     end

    #     thumbnailer.thumbnail(format, opts, &block)
    #   end

    #   it "gives preference to the block-provided settings" do
    #     opts = { resolution: :same }

    #     block = Proc.new do |input, params|
    #       params[:resolution] = '1x1'
    #     end

    #     movie.should_receive(:transcode) do |path, format_opts, codec_opts|
    #       format_opts[:resolution].should == '1x1'
    #     end

    #     thumbnailer.thumbnail(format, opts, &block)
    #   end
    # end
  end
end

