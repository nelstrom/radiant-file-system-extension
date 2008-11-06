module FileSystem::Model::PageExtensions
  IGNORED = %w{id parent_id layout_id lock_version
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
      slug = "/" if slug == "pages"
      find_or_initialize_by_slug_and_parent_id(slug, nil)
    end
    
    @@pages_on_filesystem = []
    @@page_parts_on_filesystem = []
    
    def register_page_on_filesystem(page)
      @@pages_on_filesystem << page
    end
    
    def register_page_part_on_filesystem(page_part)
      @@page_parts_on_filesystem << page_part
    end
    
    def pages_on_database
      Page.find(:all)
    end
    
    def page_parts_on_database
      PagePart.find(:all)
    end
    
    def delete_fileless_records_from_db
      fileless_page_part_ids = page_parts_on_database.map(&:id) - @@page_parts_on_filesystem.map(&:id)
      fileless_page_part_ids.each { |part_id| PagePart.destroy(part_id) }
      
      fileless_page_ids = pages_on_database.map(&:id) - @@pages_on_filesystem.map(&:id)
      fileless_page_ids.each { |page_id| Page.destroy(page_id) }
    end
    
    def load_files_with_dir_structure
      root_paths.each do |p|
        page = find_or_initialize_by_filename(p)
        page.load_file(p)
      end
      delete_fileless_records_from_db unless root_paths.blank?
    end
    
    def root_paths(path = self.path)
      Dir[path + "/"].select{|f| File.directory?(f)}
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
      puts "Loading page from #{path.sub(/#{self.class.path}\/\/?/, '/')}"
      load_attributes(yaml_file(path))
      puts "  - attributes loaded"
      load_parts(part_files(path))
      puts "  - parts loaded"
      save!
      self.class.register_page_on_filesystem(self)
      self.class.paths(path).each do |p|
        child = self.children.find_or_initialize_by_slug(File.basename(p))
        child.parent = self
        child.load_file(p)
      end
    end 
    
    def save_file_with_dir_structure(cascade=true)
      if Dir.glob(self.filename).empty?
        # no directory exists for this page, so make one
        FileUtils.mkdir_p(self.filename)
      else
        # a dir already exists for this page, so find its files and delete them
        files = Dir.glob("#{self.filename}/*.*").select{|child| File.file?(child) }
        FileUtils.rm(files)
      end
      puts "Saving #{self.filename.sub(self.class.path, '')}"
      save_attributes
      puts "  - attributes saved"
      save_parts
      puts "  - parts saved"
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
      attrs = attrs.reject {|k,v| v.blank? }
      if layout_name =~ /<inherit>/
        self.attributes = attrs.merge('layout_id' => nil)
      else
        self.attributes = attrs.merge('layout' => layout)
      end
    end

    def load_parts(files)
      files.each do |f|
        name, ext = $2, $3 if File.basename(f) =~ FileSystem::Model::FILENAME_REGEX
        filter_id = filters.include?(ext) ? ext.camelize : nil
        if part = PagePart.find_by_name_and_page_id(name, self.id)
          part.update_attributes(:filter_id => filter_id, :content => open(f).read)
        else
          part = PagePart.new(:name => name, :filter_id => filter_id, :content => open(f).read)
          self.parts << part
        end
        self.class.register_page_part_on_filesystem(part)
      end
    end
    
    def save_children
      self.children.each(&:save_file)
    end
    
    def save_parts
      self.parts.each do |part|
        part_bname = part.name
        part_ext = part.filter_id.blank? ? layout_content_type : part.filter_id.downcase
        part_fname = File.join(self.filename, [part_bname, part_ext].join("."))
        File.open(part_fname, 'w') {|f| f.write part.content }
      end
    end
    
    def save_attributes
      attr_fname = yaml_file(self.filename)
      attrs = self.attributes.dup
      IGNORED.each {|a| attrs.delete a}
      attrs['layout_name'] = layout_name_or_inherit if self.layout
      File.open(attr_fname, 'w') {|f| f.write YAML.dump(attrs) }
    end
    
    def layout_name_or_inherit
      self.layout_id ? self.layout.name : "<inherit> [#{self.layout.name}]"
    end
    
    def layout_content_type
      if self.layout
        FileSystem::Model::CONTENT_TYPES.invert[self.layout.content_type] || 'html'
      else
        'html'
      end
    end
  end
end
