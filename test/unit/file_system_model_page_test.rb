require File.dirname(__FILE__) + "/../test_helper"

class FileSystemModelPageTest < ActiveSupport::TestCase
  fixtures :pages, :page_parts
  test_helper :page, :difference
  
  def setup
    @page = Page.new
  end

  def test_should_include_special_module
    assert Page.included_modules.include?(FileSystem::Model::PageExtensions)
    assert Page.included_modules.include?(FileSystem::Model::PageExtensions::InstanceMethods)
    assert (class << Page; self; end).included_modules.include?(FileSystem::Model::PageExtensions::ClassMethods)
  end

  def test_should_redefine_class_methods
    %w{find_or_initialize_by_filename load_files save_files}.each do |method|
      assert_respond_to Page, "#{method}"
      assert_respond_to Page, "#{method}_with_dir_structure"
      assert_respond_to Page, "#{method}_without_dir_structure"
    end
  end

  def test_should_redefine_instance_methods
    %w{load_file save_file filename}.each do |method|
      assert_respond_to @page, "#{method}"
      assert_respond_to @page, "#{method}_with_dir_structure"
      assert_respond_to @page, "#{method}_without_dir_structure"
    end
  end

  def test_subclasses_should_share_path
    assert_equal Page.path, FileNotFoundPage.path
  end
  
  def test_directory_paths
    Dir.expects(:[]).with(Page.path + "/*").returns(["/slug"])
    File.expects(:directory?).with("/slug").returns(true)
    assert_equal ["/slug"], Page.paths
  end
  
  def test_part_files
    Dir.expects(:[]).with(Page.path + "/*").returns(["Part 1.html"])
    File.expects(:directory?).with("Part 1.html").returns(false)
    assert_equal ["Part 1.html"], @page.send(:part_files, Page.path)
  end
  
  def test_yaml_file
    assert_equal "/slug/slug.yaml", @page.send(:yaml_file, "/slug")
  end
  
  def test_load_parts
    assert_difference @page.parts, :size do
      @file = mock()
      @page.expects(:open).with("part file").returns(@file)
      @file.expects(:read).returns("foo")
      @page.send(:load_parts, ['part file'])
      assert_equal 'part file', @page.part('part file').name
      assert_nil @page.part('part file').filter_id
      assert_equal 'foo', @page.part('part file').content
    end
  end
  
  def test_load_attributes
    attrs = {"title" => "Inspire Your Style"}
    YAML.expects(:load_file).with("slug.yaml").returns(attrs)
    @page.send(:load_attributes, "slug.yaml")
    assert_equal "Inspire Your Style", @page.title
  end
  
  def test_load_file
    @child = mock()
    @page.expects(:yaml_file).with("/slug").returns("/slug/slug.yaml")
    @page.expects(:load_attributes).with("/slug/slug.yaml").returns(true)
    @page.expects(:part_files).with("/slug").returns(['/slug/Part 1.html'])
    @page.expects(:load_parts).with(['/slug/Part 1.html']).returns(true)
    @page.expects(:save!).returns(true)
    Page.expects(:paths).with("/slug").returns(["/slug/slug-two"])
    @page.children.expects(:find_or_initialize_by_slug).returns(@child)
    @child.expects(:parent=).with(@page).returns(@page)
    @child.expects(:load_file).with("/slug/slug-two").returns(true)
    @page.load_file("/slug")
  end
  
  def test_should_have_filename_based_on_page_hierarchy
    assert_equal "#{RAILS_ROOT}/design/pages/", pages(:homepage).filename
    assert_equal "#{RAILS_ROOT}/design/pages/documentation/books", pages(:books).filename
  end
  
  def test_should_save_file_as_attributes_parts_and_children_separately
    @page.stubs(:filename).returns("blah")
    FileUtils.expects(:mkdir_p).with("blah").returns(true)
    # FileUtils.expects(:rm).with("blah").returns(true)
    @page.expects(:save_attributes).returns(true)
    @page.expects(:save_parts).returns(true)
    @page.expects(:save_children).returns(true)
    @page.save_file
  end
  
  def test_should_save_children_recursively
    @child_mock = mock()
    @page.expects(:children).returns([@child_mock])
    @child_mock.expects(:save_file).returns(true)
    @page.send :save_children
  end
  
  def test_should_save_parts_to_individual_files
    @part_plain = mock()
    @part_textile = mock()
    @file_mock = mock()
    @page.expects(:parts).returns([@part_plain, @part_textile])
    @part_plain.expects(:filter_id).at_least_once.returns(nil)
    @part_plain.expects(:name).returns("body")
    @part_plain.expects(:content).returns("foo")
    @part_textile.expects(:filter_id).at_least_once.returns("Textile")
    @part_textile.expects(:name).returns("extended")
    @part_textile.expects(:content).returns("bar")
    @page.expects(:filename).at_least_once.returns("slug")
    File.expects(:open).with("slug/body.html", 'w').yields(@file_mock)
    @file_mock.expects(:write).with("foo")
    File.expects(:open).with("slug/extended.textile", 'w').yields(@file_mock)
    @file_mock.expects(:write).with("bar")
    @page.send :save_parts
  end
  
  def test_should_save_attributes_to_yaml_file
    @file_mock = mock()
    @layout_mock = mock()
    @yaml_mock = mock()
    @attrs = {"title" => "My page", "slug" => "slug", "layout_id" => 1}
    @page.expects(:filename).returns("slug")
    @page.expects(:yaml_file).returns("slug/slug.yaml")
    @page.expects(:attributes).returns(@attrs)
    @page.expects(:layout_id).returns(1)
    @page.expects(:layout).at_least_once.returns(@layout_mock)
    @layout_mock.expects(:name).returns("My layout")
    File.expects(:open).with("slug/slug.yaml", 'w').yields(@file_mock)
    YAML.expects(:dump).with({"title" => "My page", "slug" => "slug", "layout_name" => "My layout"}).returns(@yaml_mock)
    @file_mock.expects(:write).with(@yaml_mock)
    @page.send :save_attributes
  end
end
