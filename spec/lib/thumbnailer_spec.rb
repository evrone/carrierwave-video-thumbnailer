require 'spec_helper'
require 'carrierwave/video/thumbnailer'

describe CarrierWave::Video::Thumbnailer do

  it "should have a VERSION constant" do
    subject.const_get('VERSION').should_not be_empty
  end

  #class FFMpegThumbnailer; end

  class TestVideoUploader
    include CarrierWave::Video::Thumbnailer
    def cached?; end
    def cache_stored_file!; end
    def model
      @thumbnailer ||= FFMpegThumbnailer.new
    end
  end

  let(:uploader) { TestVideoUploader.new }

  describe ".thumbnail" do
    it "processes the model" do
      TestVideoUploader.should_receive(:process).with(thumbnail: {option: 'something'})
      TestVideoUploader.thumbnail({option: 'something'})
    end

    it "does not require options" do
      TestVideoUploader.should_receive(:process).with(thumbnail: {})
      TestVideoUploader.thumbnail
    end
  end

  describe "#thumbnail" do
    let(:format)      { 'jpg' }
    let(:thumbnailer) { mock  }

    before do
      uploader.stub(:current_path).and_return('video/path/file.jpg')

      CarrierWave::Video::Thumbnailer::FFMpegThumbnailer.should_receive(:new).at_most(10).times.and_return(thumbnailer)
    end

    context "with no options set" do
      before {  File.should_receive(:rename).with('video/path/tmpfile.jpg', 'video/path/file.jpg') }

      it "runs the thumbnailer with empty options list" do
        thumbnailer.should_receive(:run) do |options|
          expect(options.options).to be_empty
        end
        uploader.thumbnail
      end
    end

    context "with callbacks set" do
      before { thumbnailer.should_receive(:run) }
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
        before {  File.should_receive(:rename).with('video/path/tmpfile.jpg', 'video/path/file.jpg') }

        it "calls before_thumbnail, after_thumbnail, and ensure" do
          uploader.model.should_receive(:method1).with(an_instance_of CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions).ordered
          uploader.model.should_receive(:method2).with(an_instance_of CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions).ordered
          uploader.model.should_not_receive(:method3)
          uploader.model.should_receive(:method4).with(an_instance_of CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions).ordered

          uploader.thumbnail(opts)
        end
      end

      context "exception raised" do
        let(:e) { StandardError.new("test error") }
        before { File.should_receive(:rename).and_raise(e) }


        it "calls before_thumbnail and ensure" do
          uploader.model.should_receive(:method1).with(an_instance_of CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions).ordered
          uploader.model.should_not_receive(:method2)
          uploader.model.should_receive(:method3).with(an_instance_of CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions).ordered
          uploader.model.should_receive(:method4).with(an_instance_of CarrierWave::Video::Thumbnailer::FFMpegThumbnailerOptions).ordered

          lambda do
            uploader.thumbnail(opts)
          end.should raise_exception(CarrierWave::ProcessingError)
        end
      end
    end

    context "with logger set" do
      let(:logger) { mock }
      before do
        uploader.model.stub(:logger).and_return(logger)
        thumbnailer.should_receive(:run)
      end

      context "with no exceptions" do
        before { File.should_receive(:rename).with('video/path/tmpfile.jpg', 'video/path/file.jpg') }

        it "sets FFMpegThumbnailer logger to logger and resets" do
          old_logger = CarrierWave::Video::Thumbnailer::FFMpegThumbnailer.logger
          CarrierWave::Video::Thumbnailer::FFMpegThumbnailer.should_receive(:logger=).with(logger).ordered
          CarrierWave::Video::Thumbnailer::FFMpegThumbnailer.should_receive(:logger=).with(old_logger).ordered
          uploader.thumbnail(logger: logger)
        end
      end

      context "with exceptions" do
        let(:e) { StandardError.new("test error") }
        before { File.should_receive(:rename).with('video/path/tmpfile.jpg', 'video/path/file.jpg').and_raise(e) }

        it "logs exception" do
          logger.should_receive(:error).with("#{e.class}: #{e.message}")
          logger.should_receive(:error).any_number_of_times  # backtrace

          lambda do
            uploader.thumbnail(logger: logger)
          end.should raise_exception(CarrierWave::ProcessingError)
        end
      end
    end

    context "with custom passed in" do
      before { File.should_receive(:rename).with('video/path/tmpfile.jpg', 'video/path/file.jpg') }

      it "takes the provided custom param" do
        thumbnailer.should_receive(:run) do |opts|
          opts.custom.should eq '-s 256'
        end

        uploader.thumbnail(custom: '-s 256')
      end
    end

  end
end

