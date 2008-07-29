require File.dirname(__FILE__) + "/../test_helper"

class FileSystemModelTemplateTest < Test::Unit::TestCase
  
  def setup
    @template = Template.new :name => "A template", :content => "", :layout_id => 1
    @yaml = {'layout_name' => 'default', 
             1 => {'name' => "part 1", 'filter_id' => nil, 'part_type_name' => 'WYSIWYG', 'description' => "The main content"}, 
             2 => {'name' => 'part 2', 'filter_id' => "Textile", 'part_type_name' => 'Plain', 'description' => 'The sidebar'}}
    @parts = @yaml.inject([]) do |ary,(id,attrs)|
      if attrs.is_a? Hash
        part_mock = mock()
        part_type = mock()
        part_mock.stubs(:id).returns(id)
        part_mock.stubs(:name).returns(attrs['name'])
        part_mock.stubs(:filter_id).returns(attrs['filter_id'])
        part_mock.stubs(:part_type).returns(part_type)
        part_type.stubs(:name).returns(attrs['part_type_name'])
        part_mock.stubs(:description).returns(attrs['description'])
        ary << part_mock
      else
        ary
      end
    end
    @file_mock = mock()
  end

  def test_should_intercept_load
    assert_respond_to @template, :load_file_with_parts
    assert_respond_to @template, :load_file_without_parts
  end
  
  def test_should_not_load_default_when_yaml_file
    @template.expects(:layout_name=).returns('blah')
    @template.expects(:load_file_without_parts).never
    @template.load_file(File.dirname(__FILE__) + "/../fixtures/005_some_name.yaml")
  end
  
  def test_should_update_template_parts_and_layout_when_yaml_file
    @template.expects(:layout_name=).returns('blah')
    @template.expects(:page_class_name=).with(nil).returns(nil)
    @template.expects(:template_parts=).with(instance_of(Hash))
    @template.load_file(File.dirname(__FILE__) + "/../fixtures/005_some_name.yaml")
  end

  def test_template_parts_should_retain_order_when_loaded_from_yaml_file
    @template.expects(:layout_name=).returns('blah')
    @template.load_file(File.dirname(__FILE__) + "/../fixtures/005_some_name.yaml")
    assert_valid @template
    assert_equal "part 1", @template.template_parts.first.name
    assert_nil @template.template_parts.first.filter_id
    assert_equal "part 2", @template.template_parts.last.name
    assert_equal "Textile", @template.template_parts.last.filter_id
  end
  
  def test_should_assign_layout_by_name
    @layout = mock()
    Layout.expects(:find_by_name).with("blah").returns(@layout)
    @template.expects(:layout=).with(@layout).returns(@layout)
    @template.load_file(File.dirname(__FILE__) + "/../fixtures/005_some_name.yaml")
  end
  
  def test_should_have_filename_based_on_name
    assert_equal "A template.html", File.basename(@template.filename)
  end
  
  def test_should_save_content_and_attributes_in_separate_files
    @layout_mock, @yaml_mock = mock(), mock()
    @template.expects(:save_file_without_parts).returns(true)
    @template.expects(:template_parts).returns(@parts)
    @template.expects(:filename).at_least_once.returns("A template.html")
    @template.expects(:layout).returns(@layout_mock)
    @layout_mock.expects(:name).returns("default")
    File.expects(:open).with("A template.yaml", 'w').yields(@file_mock)
    YAML.expects(:dump).with(@yaml).returns(@yaml_mock)
    @file_mock.expects(:write).with(@yaml_mock).returns(true)
    @template.save_file
  end
  
  def test_content_should_be_saved_in_html_file
    @template.content = "Some content"
    @template.name = "a model"
    @file_mock = mock()
    File.expects(:open).with("#{RAILS_ROOT}/design/templates/a model.html", 'w').yields(@file_mock)
    @file_mock.expects(:write).with("Some content")
    @template.save_file_without_parts
  end
  
  def test_should_load_files
    @template_mock = mock()
    Dir.expects(:[]).with("#{RAILS_ROOT}/design/templates/*.yaml", "#{RAILS_ROOT}/design/templates/*.yml").returns(["#{RAILS_ROOT}/design/templates/one.yaml"])
    Template.expects(:find_or_initialize_by_filename).with("#{RAILS_ROOT}/design/templates/one.yaml").returns(@template_mock)
    @template_mock.expects(:load_file).with("#{RAILS_ROOT}/design/templates/one.yaml")
    Dir.expects(:[]).with("#{RAILS_ROOT}/design/templates/one*").returns(["#{RAILS_ROOT}/design/templates/one.yaml", "#{RAILS_ROOT}/design/templates/one.html", "#{RAILS_ROOT}/design/templates/one_and_two.yaml", "#{RAILS_ROOT}/design/templates/one_and_two.html"])
    @template_mock.expects(:load_file).with("#{RAILS_ROOT}/design/templates/one.html")
    @template_mock.expects(:save!)
    Template.load_files
  end
end
