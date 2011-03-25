require File.dirname(__FILE__) + '/../spec_helper'

class MockTextAsset
  def self.class_of_active_record_descendant(klass)
    MockTextAsset
  end
end

describe TextAsset do

  before :each do
    MockTextAsset.send :include, FileSystem::Model
    MockTextAsset.send :include, FileSystem::Model::TextAssetExtensions
    @model = MockTextAsset.new
  end

  [
    FileSystem::Model, 
    FileSystem::Model::TextAssetExtensions,
    FileSystem::Model::TextAssetExtensions::InstanceMethods
  ].each do |module_name|
    it "should include #{module_name} module" do
      TextAsset.included_modules.should include(module_name)
    end
  end

  it "should include FileSystem::Model::TextAssetExtensions::ClassMethods module" do
    (class << TextAsset; self; end).included_modules.
        should include(FileSystem::Model::TextAssetExtensions::ClassMethods)
  end

  it "should have class methods" do
    [:path, :load_files, :save_files].each do |m|
      MockTextAsset.should respond_to(m)
    end
  end

  it "should have instance methods" do
    @model.should respond_to(:load_file)
    @model.should respond_to(:save_file)
    @model.should respond_to(:filename)
  end

  %w{load_files}.each do |method|
    it "should redefine #{method} class method" do
      TextAsset.should respond_to("#{method}")
      TextAsset.should respond_to("#{method}_with_subfolder")
      TextAsset.should respond_to("#{method}_without_subfolder")
    end
  end

  %w{filename load_file}.each do |method|
    it "should redefine #{method} instance method" do
      @model.should respond_to("#{method}")
      @model.should respond_to("#{method}_with_subfolder")
      @model.should respond_to("#{method}_without_subfolder")
    end
  end
  
  it "should return each file representing a javascript on the filesystem" do
    Dir.should_receive(:[]).with(MockTextAsset.path + "/Javascript/*").and_return(["/example_name.js"])
    MockTextAsset.javascripts.should == ["/example_name.js"]
  end

  it "should return each file representing a stylesheet on the filesystem" do
    Dir.should_receive(:[]).with(MockTextAsset.path + "/Stylesheet/*").and_return(["/example_name.css"])
    MockTextAsset.stylesheets.should == ["/example_name.css"]
  end
  

  describe "filename" do
    describe "extension" do
      before(:each) do
        class << @model
          attr_accessor :name
          attr_accessor :class_name
        end
      end

      describe "javascripts" do
        before(:each) do
          @model.name = "example_name.js"
          @model.class_name = "Javascript"
        end
        it "should use subfolder use class_name" do
          @model.filename.should == "#{RAILS_ROOT}/design/mock_text_assets/Javascript/example_name.js"
        end
      end

      describe "stylesheets" do
        before(:each) do
          @model.name = "example_name.css"
          @model.class_name = "Stylesheet"
        end
        it "should use subfolder using class_name" do
          @model.filename.should == "#{RAILS_ROOT}/design/mock_text_assets/Stylesheet/example_name.css"
        end
      end
    end
  end

  describe "load_file" do
    before(:each) do
      class << @model
        attr_accessor :name, :content, :class_name
      end
      @model.name = "Original name"
      @model.content = "Original content in the database"
      @model.should_receive(:save!).and_return(true)
      @file_mock = mock("file_mock")
      @file_mock.should_receive(:read).and_return("Content stored in a file")
    end
    
    it "should set class_name name from filename" do
      @model.should_receive(:open).with("Javascript/example_name.js").and_return(@file_mock)
      @model.load_file("Javascript/example_name.js")
      @model.class_name.should == "Javascript"
    end

  end
  describe "save_file" do
    before(:each) do
      class << @model
        attr_accessor :content, :name, :class_name
      end
      @model.content = "Existing model content"
      @model.name = "example_model.js"
      @model.class_name = "Javascript"
      @file_mock = mock("file_mock")
    end
    
    it "should save file with class_name" do
      File.should_receive(:open).
        with("#{RAILS_ROOT}/design/mock_text_assets/Javascript/example_model.js", 'w').
        and_yield(@file_mock)
      @file_mock.should_receive(:write).with("Existing model content")
      @model.save_file
    end
    
  end
end