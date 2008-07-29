require File.dirname(__FILE__) + "/../test_helper"

class FileSystemModelPartTypeTest < Test::Unit::TestCase
  def setup
    @part_type = PartType.new :name => "Test", :field_type => "hidden", :field_class => "test"
  end
  
  def test_should_define_content_type
    assert_respond_to @part_type, :content_type
    assert_respond_to @part_type, :content_type=
    assert_equal "text/x-yaml", @part_type.content_type
  end
  
  def test_should_have_filename_ending_in_yaml
    assert_match /\.yaml$/, @part_type.filename
  end
  
  def test_should_not_change_content_type
    @part_type.content_type = "text/html"
    assert_equal "text/x-yaml", @part_type.content_type
  end
  
  def test_should_have_yaml_content
    assert_match /^---\s*\w+:/m, @part_type.content
  end
  
  def test_should_load_attributes_from_yaml
    hash = {'field_type' => 'text_field', 'field_class' => 'text', 'field_styles' => 'width: 500px;'}
    yaml = hash.to_yaml
    @part_type.content = yaml
    hash.each do |k,v|
      assert_equal v, @part_type[k]
    end
  end
end
