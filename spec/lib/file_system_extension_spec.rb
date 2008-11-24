require File.dirname(__FILE__) + '/../spec_helper'

describe "FileSystemExtension" do
  [Layout, Snippet, Page].each do |model|
    it "should include FileSystem::Model in #{model.to_s}" do
      model.included_modules.should include(FileSystem::Model)
    end
  end
  
  it "should include specialized PageExtensions in Page model" do
    Page.included_modules.should include(FileSystem::Model::PageExtensions)
  end
  
  it "should set the extension's root path" do
    FileSystemExtension.root.should == File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'file_system')
  end
  
  it "should set extension name" do
    FileSystemExtension.extension_name.should == "File System"
  end
end