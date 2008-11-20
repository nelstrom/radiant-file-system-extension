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
  
  describe "load_file" do
    before(:each) do
      class << @model
        attr_accessor :name, :content
      end
      @model.name = "Original name"
      @model.content = "Original content in the database"
      @file_mock = mock("file_mock")
      @file_mock.should_receive(:read).and_return("Content stored in a file")
    end
    
    it "should set model name from filename" do
      @model.should_receive(:open).with("005_new_name").and_return(@file_mock)
      @model.load_file("005_new_name")
      @model.name.should == "new_name"
    end
    
    it "should set content type from file content_type" do
      class << @model
        attr_accessor :content_type
      end
      @model.content_type = "text/plain"
      @model.should_receive(:open).with("005_new_name.html").and_return(@file_mock)
      @model.load_file("005_new_name.html")
      @model.content_type.should == "text/html"
    end
    
    it "should nullify content type when changed" do
      class << @model
        attr_accessor :content_type
      end
      @model.content_type = "text/plain"
      @model.should_receive(:open).with("005_new_name").and_return(@file_mock)
      @model.load_file("005_new_name")
      @model.content_type.should be_nil
    end
    
    it "should set filter_id from file extension" do
      class << @model
        attr_accessor :filter_id
      end
      @model.filter_id = "Textile"
      @model.should_receive(:open).with("005_new_name.markdown").and_return(@file_mock)
      @model.load_file("005_new_name.markdown")
      @model.filter_id.should == "Markdown"
    end
    
    it "should nullify filter_id when changed" do
      class << @model
        attr_accessor :filter_id
      end
      @model.filter_id = "Textile"
      @model.should_receive(:open).with("005_new_name").and_return(@file_mock)
      @model.load_file("005_new_name")
      @model.filter_id.should be_nil
    end
    
  end
  
end
