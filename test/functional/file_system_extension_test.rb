require File.dirname(__FILE__) + '/../test_helper'

class FileSystemExtensionTest < Test::Unit::TestCase
  
  def test_basic_module_inclusion
    [Layout, Snippet, Page].each do |model|
      assert model.included_modules.include?(FileSystem::Model)
    end
  end
  
  def test_specialized_module_inclusion
    assert Page.included_modules.include?(FileSystem::Model::PageExtensions)
  end
  
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'file_system'), FileSystemExtension.root
    assert_equal 'File System', FileSystemExtension.extension_name
  end
end
