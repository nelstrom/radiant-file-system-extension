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
    
    # it "should have original filename" do
    #   @model.name.should == "Original name"
    # end
    it "should set model name from filename" do
      @model.should_receive(:open).with("005_new_name").and_return(@file_mock)
      @model.load_file("005_new_name")
      @model.name.should == "new_name"
    end
    
    # it "should have original content" do
    #   @model.content.should == "Original content in the database"
    # end
    it "should set content from the file contents" do
      @model.should_receive(:open).with("005_new_name").and_return(@file_mock)
      @model.load_file("005_new_name")
      @model.content.should == "Content stored in a file"
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
  
  describe "filename" do
    before(:each) do
      class << @model
        attr_accessor :name
      end
      @model.name = "example_name"
    end
    it "should use name with default extension" do
      @model.filename.should == "#{RAILS_ROOT}/design/mock_models/example_name.html"
    end
    it "should use filter as extension" do
      class << @model
        attr_accessor :filter_id
      end
      @model.filter_id = "Textile"
      @model.filename.should == "#{RAILS_ROOT}/design/mock_models/example_name.textile"
    end
  end
  
  describe "save_file" do
    before(:each) do
      class << @model
        attr_accessor :content, :name
      end
      @model.content = "Existing model content"
      @model.name = "example_model"
      @file_mock = mock("file_mock")
    end
    
    it "should save file" do
      File.should_receive(:open).
        with("#{RAILS_ROOT}/design/mock_models/example_model.html", 'w').
        and_yield(@file_mock)
      @file_mock.should_receive(:write).with("Existing model content")
      @model.save_file
    end
    
    it "should save file with filter" do
      class << @model
        attr_accessor :filter_id
      end
      @model.filter_id = "Textile"
      File.should_receive(:open).
        with("#{RAILS_ROOT}/design/mock_models/example_model.textile", 'w').
        and_yield(@file_mock)
      @file_mock.should_receive(:write).with("Existing model content")
      @model.save_file
    end
    
    it "should save file with content_type" do
      class << @model
        attr_accessor :content_type
      end
      @model.content_type = "text/css"
      File.should_receive(:open).
        with("#{RAILS_ROOT}/design/mock_models/example_model.css", 'w').
        and_yield(@file_mock)
      @file_mock.should_receive(:write).with("Existing model content")
      @model.save_file
    end
    
  end
  
  describe "allowed filenames" do
    ['001_some_name',
    '001_some-name',
    '002_name_with.ext',
    '002_name-with.ext',
    '003_name_with.ext-dash',
    '003_name-with.ext-dash',
    'some_name',
    'some-name',
    'name_with.ext',
    'name-with.ext',
    'name_with.ext-dash',
    'name-with.ext-dash',
    'File with spaces.html',
    %{\!\@\#\$\%\^\&\*\(\)\[\]\{\}\|\=\-\_\+\/\*\'\"\;\:\,\<\>\`\~.html}
    ].each do |filename|
      it "should include #{filename}" do
        filename.should match(FileSystem::Model::FILENAME_REGEX)
      end
    end
  end
  
  describe "disallowed filenames" do
    [].each do |filename|
      it "should include #{filename}" do
        filename.should_not match(FileSystem::Model::FILENAME_REGEX)
      end
    end
  end
  
end
