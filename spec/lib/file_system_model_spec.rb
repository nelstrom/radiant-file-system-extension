require File.dirname(__FILE__) + '/../spec_helper'

class MockModel
  def self.class_of_active_record_descendant(klass)
    MockModel
  end
end

class MockSubclass < MockModel
end

def mock_filepath
  "#{RAILS_ROOT}/design/mock_models"
end

describe FileSystem::Model do
  
  before :each do
    MockModel.send :include, FileSystem::Model
    @model = MockModel.new
  end
  
  it "should include FileSystem::Model module" do
    MockModel.included_modules.should include(FileSystem::Model)
  end
  
  it "should have class methods" do
    [:path, :load_files, :save_files].each do |m|
      MockModel.should respond_to(m)
    end
  end
  
  it "should have instance methods" do
    @model.should respond_to(:load_file)
    @model.should respond_to(:save_file)
    @model.should respond_to(:filename)
  end
  
  describe "path" do
    it "should be created from class_of_active_record_descendant" do
      MockModel.path.should == mock_filepath
    end
    it "should be inherited by child objects" do
      MockSubclass.path.should == mock_filepath
    end
  end
  
  
  
end
