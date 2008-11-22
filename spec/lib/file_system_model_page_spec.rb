require File.dirname(__FILE__) + '/../spec_helper'

class MockPage
  def self.class_of_active_record_descendant(klass)
    MockPage
  end
end

def mock_filepath
  "#{RAILS_ROOT}/design/mock_pages"
end

describe Page do
  
  before :each do
    MockPage.send :include, FileSystem::Model
    MockPage.send :include, FileSystem::Model::PageExtensions
    @model = MockPage.new
  end
  
  [
    FileSystem::Model, 
    FileSystem::Model::PageExtensions,
    FileSystem::Model::PageExtensions::InstanceMethods
  ].each do |module_name|
    it "should include #{module_name} module" do
      Page.included_modules.should include(module_name)
    end
  end
  
  it "should include FileSystem::Model::PageExtensions::ClassMethods module" do
    (class << Page; self; end).included_modules.
        should include(FileSystem::Model::PageExtensions::ClassMethods)
  end
  
end