require 'spec_helper'
require 'carrierwave/video/thumbnailer'

describe Carrierwave::Video::Thumbnailer do
  it "should have a VERSION constant" do
    subject.const_get('VERSION').should_not be_empty
  end
end
