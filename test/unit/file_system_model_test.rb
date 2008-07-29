require File.dirname(__FILE__) + "/../test_helper"

class MockModel
  def self.class_of_active_record_descendant(klass)
    MockModel
  end
end

class MockSubclass < MockModel
end

class FileSystemModelTest < Test::Unit::TestCase
  
  def setup
    MockModel.send :include, FileSystem::Model
    @model = MockModel.new
  end
    
  def test_should_have_class_methods
    [:path, :load_files, :save_files].each do |m|
      assert_respond_to MockModel, m
    end
  end
  
  def test_should_have_instance_methods
    assert_respond_to @model, :load_file
    assert_respond_to @model, :save_file
    assert_respond_to @model, :filename    
  end
  
  def test_should_have_a_canonical_path
    assert_equal RAILS_ROOT + "/design/mock_models", MockModel.path
    assert_equal MockModel.path, MockSubclass.path
  end
  
  def test_should_load_file
    @file_mock = mock()
    @model.stubs(:id).returns(5)
    class << @model
      attr_accessor :name, :content
    end
    @model.name = "My name"
    @model.content = "bar"
    @model.expects(:open).with("005_new_name").returns(@file_mock)
    @file_mock.expects(:read).returns("foo")
    @model.load_file("005_new_name")
    assert_equal "new_name", @model.name
    assert_equal "foo", @model.content
  end
  
  def test_should_load_file_with_content_type
    @file_mock = mock()
    @model.stubs(:id).returns(5)
    class << @model
      attr_accessor :name, :content, :content_type
    end
    @model.name = "My name"
    @model.content = "bar"
    @model.content_type = "text/plain"
    @model.expects(:open).with("005_new_name.html").returns(@file_mock)
    @file_mock.expects(:read).returns("foo")
    @model.load_file("005_new_name.html")
    assert_equal "new_name", @model.name
    assert_equal "foo", @model.content
    assert_equal "text/html", @model.content_type
  end
  
  def test_should_load_file_with_filter_id
    @file_mock = mock()
    @model.stubs(:id).returns(5)
    class << @model
      attr_accessor :name, :content, :filter_id
    end
    @model.name = "My name"
    @model.content = "bar"
    @model.filter_id = "Textile"
    @model.expects(:open).with("005_new_name.markdown").returns(@file_mock)
    @file_mock.expects(:read).returns("foo")
    @model.load_file("005_new_name.markdown")
    assert_equal "new_name", @model.name
    assert_equal "foo", @model.content
    assert_equal "Markdown", @model.filter_id
  end
  
  def test_should_nullify_content_type_when_changed
    @file_mock = mock()
    @model.stubs(:id).returns(5)
    class << @model
      attr_accessor :name, :content, :content_type
    end
    @model.name = "My name"
    @model.content = "bar"
    @model.content_type = "text/plain"
    @model.expects(:open).with("005_new_name").returns(@file_mock)
    @file_mock.expects(:read).returns("foo")
    @model.load_file("005_new_name")
    assert_equal "new_name", @model.name
    assert_equal "foo", @model.content
    assert_equal nil, @model.content_type
  end
  
  def test_should_nullify_filter_id_when_changed
    @file_mock = mock()
    @model.stubs(:id).returns(5)
    class << @model
      attr_accessor :name, :content, :filter_id
    end
    @model.name = "My name"
    @model.content = "bar"
    @model.filter_id = "Textile"
    @model.expects(:open).with("005_new_name").returns(@file_mock)
    @file_mock.expects(:read).returns("foo")
    @model.load_file("005_new_name")
    assert_equal "new_name", @model.name
    assert_equal "foo", @model.content
    assert_equal nil, @model.filter_id
  end
    
  def test_filename
  end
  
  def test_should_save_file
    class << @model
      attr_accessor :content, :name
    end
    @model.content = "Some content"
    @model.name = "a model"
    @file_mock = mock()
    File.expects(:open).with("#{RAILS_ROOT}/design/mock_models/a model.html", 'w').yields(@file_mock)
    @file_mock.expects(:write).with("Some content")
    @model.save_file
  end
  
  def test_should_save_file_with_filter
    class << @model
      attr_accessor :content, :name, :filter_id
    end
    @model.content = "Some content"
    @model.name = "a model"
    @model.filter_id = "Textile"
    @file_mock = mock()
    File.expects(:open).with("#{RAILS_ROOT}/design/mock_models/a model.textile", 'w').yields(@file_mock)
    @file_mock.expects(:write).with("Some content")
    @model.save_file
  end

  def test_should_save_file_with_content_type
    class << @model
      attr_accessor :content, :name, :content_type
    end
    @model.content = "Some content"
    @model.name = "a model"
    @model.content_type = "text/css"
    @file_mock = mock()
    File.expects(:open).with("#{RAILS_ROOT}/design/mock_models/a model.css", 'w').yields(@file_mock)
    @file_mock.expects(:write).with("Some content")
    @model.save_file
  end
  
  def test_filename_matches
    r = FileSystem::Model::FILENAME_REGEX
    assert_match r, '001_some_name'
    assert_match r, '001_some-name'
    assert_match r, '002_name_with.ext'
    assert_match r, '002_name-with.ext'
    assert_match r, '003_name_with.ext-dash'
    assert_match r, '003_name-with.ext-dash'

    assert_match r, 'some_name'
    assert_match r, 'some-name'
    assert_match r, 'name_with.ext'
    assert_match r, 'name-with.ext'
    assert_match r, 'name_with.ext-dash'
    assert_match r, 'name-with.ext-dash'
    
    assert_match r, 'File with spaces.html'
    
    assert_match r, %{\!\@\#\$\%\^\&\*\(\)\[\]\{\}\|\=\-\_\+\/\*\'\"\;\:\,\<\>\`\~.html}
  end
end
