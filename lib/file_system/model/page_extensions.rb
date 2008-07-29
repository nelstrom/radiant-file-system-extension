module FileSystem::Model::PageExtensions
  IGNORED = %w{id lock_version draft_of parent_id layout_id
              created_by created_at updated_by updated_at}
  
  def self.included(base)   
    # Instance methods
    base.class_eval do
      extend ClassMethods
      include InstanceMethods
      %w{load_file save_file filename}.each do |m|
        alias_method_chain m.to_sym, :dir_structure
      end 
    end
    # Singleton/class methods
    class << base
      %w{find_or_initialize_by_filename load_files save_files}.each do |m|
        alias_method_chain m.to_sym, :dir_structure
      end
    end
  end
  
  module ClassMethods
    def find_or_initialize_by_filename_with_dir_structure(filename)
      slug = File.basename(filename)
      find_or_initialize_by_slug_and_parent_id_and_draft_of(slug, nil, nil)
    end
    
    def load_files_with_dir_structure
      paths.each do |p|
        page = find_or_initialize_by_filename(p)
        page.load_file(p)
      end
    end
    
    def paths(path = self.path)
      Dir[path + "/*"].select{|f| File.directory?(f)}
    end
    
    def save_files_with_dir_structure
      roots.each(&:save_file)
    end
  end

  module InstanceMethods
    def load_file_with_dir_structure(path)
      puts "Loading page from #{path.sub(self.class.path, '')}"
      load_attributes(yaml_file(path))
      puts "  - attributes loaded"
      load_parts(part_files(path))
      puts "  - parts loaded"
      save!
      self.class.paths(path).each do |p|
        child = self.children.find_or_initialize_by_slug(File.basename(p))
        child.parent = self
        child.load_file(p)
      end
    end 
    
    def save_file_with_dir_structure(cascade=true)
      FileUtils.rm_rf(self.filename)
      FileUtils.mkdir_p(self.filename)
      save_attributes
      save_parts
      save_children if cascade
    end
    
    def filename_with_dir_structure
      File.join([self.class.path, self.ancestors.reverse.map(&:slug), self.slug].flatten)
    end
    

    def part_files(path)
      Dir[path + "/*"].select{|f| !File.directory?(f) && f !~ /\.ya?ml$/ }
    end
    
    def yaml_file(path)
      slug = File.basename(path)
      File.join(path, slug + ".yaml")
    end
    
    def load_attributes(yml_file)
      attrs = YAML.load_file(yml_file)
      layout_name = attrs.delete('layout_name')
      layout = Layout.find_by_name(layout_name) if layout_name
      IGNORED.each {|a| attrs.delete a }
      self.attributes = attrs.merge('_layout' => layout).reject {|k,v| v.blank? }
    end

    def load_parts(files)
      files.each do |f|
        name, ext = $2, $3 if File.basename(f) =~ FileSystem::Model::FILENAME_REGEX
        filter_id = FileSystem::Model::FILTERS.include?(ext) ? ext.camelize : nil
        self.parts << PagePart.new(:name => name, :filter_id => filter_id, :content => open(f).read)
      end
    end
    
    def save_children
      self.children.each(&:save_file)
    end
    
    def save_parts
      self.parts.each do |part|
        part_bname = part.name
        part_ext = part.filter_id.blank? ? "html" : part.filter_id.downcase
        part_fname = File.join(self.filename, [part_bname, part_ext].join("."))
        File.open(part_fname, 'w') {|f| f.write part.content }
      end
    end
    
    def save_attributes
      attr_fname = yaml_file(self.filename)
      attrs = self.attributes.dup
      IGNORED.each {|a| attrs.delete a}
      attrs['layout_name'] = self.layout.name if self.layout
      File.open(attr_fname, 'w') {|f| f.write YAML.dump(attrs) }
    end
  end
end
