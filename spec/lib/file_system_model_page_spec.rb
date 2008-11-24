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
  
  %w{find_or_initialize_by_filename load_files save_files}.each do |method|
    it "should redefine #{method} class method" do
      Page.should respond_to("#{method}")
      Page.should respond_to("#{method}_with_dir_structure")
      Page.should respond_to("#{method}_without_dir_structure")
    end
  end
  
  %w{load_file save_file filename}.each do |method|
    it "should redefine #{method} instance method" do
      @model.should respond_to("#{method}")
      @model.should respond_to("#{method}_with_dir_structure")
      @model.should respond_to("#{method}_without_dir_structure")
    end
  end
  
  it "should return each directory representing a page on the filesystem" do
    Dir.should_receive(:[]).with(MockPage.path + "/*").and_return(["/slug"])
    File.should_receive(:directory?).with("/slug").and_return(true)
    MockPage.paths.should == ["/slug"]
  end
  
  it "should return files representing page parts" do
    Dir.should_receive(:[]).with(MockPage.path + "/*").and_return(["Part 1.html"])
    File.should_receive(:directory?).with("Part 1.html").and_return(false)
    @model.part_files(MockPage.path)
  end
  
  it "should return path for yaml file using page slug as filename" do
    @model.yaml_file("/slug").should == "/slug/slug.yaml"
  end
  
  it "should load parts" do
    # the load_parts methods includes a call to:
    #   self.parts << part
    # which is not immplemented for @model (MockPage)
    # hence the change to using @page
    @page = Page.new
    @file_mock = mock("file_mock")
    @page.should_receive(:open).with("part file").and_return(@file_mock)
    @file_mock.should_receive(:read).and_return("Content in the file")
    @page.load_parts(["part file"])
    
    @page.part("part file").name.should == 'part file'
    @page.part("part file").filter_id.should == nil
    @page.part("part file").content.should == "Content in the file"
  end
  
end

describe FileNotFoundPage do
  it "should inherit path from Page" do
    FileNotFoundPage.path.should == Page.path
  end
end