require 'yaml'
module FileSystem::Model::TemplateExtensions
  def self.included(base)
    base.class_eval do
      alias_method_chain :load_file, :parts
      alias_method_chain :save_file, :parts
    end
    class << base
      def load_files
        Dir[self.path + "/*.yaml", self.path + "/*.yml"].each do |yml|
          template = find_or_initialize_by_filename(yml)
          puts "Loading template attributes (and parts) from #{File.basename(yml)}"
          template.load_file(yml)
          basename = yml.sub(/\.ya?ml/, "")
          content = Dir[basename + "*"].reject {|f| f =~ /\.ya?ml/ }.find {|f| f =~ /#{basename}(\.|$)/ }
          puts "Loading template content from #{File.basename(content)}"
          template.load_file(content) if content
          template.save!
        end
      end
    end
  end

  def load_file_with_parts(filename)
    if filename =~ /\.ya?ml$/
      if yml = YAML::load_file(filename)
        self.layout_name = yml.delete('layout_name')
        self.page_class_name = yml.delete('page_class_name')
        self.template_parts = yml
      end
    else
      load_file_without_parts(filename)
    end 
  end
  
  def save_file_with_parts
    save_file_without_parts
    hash = self.template_parts.inject({}) do |h,part|
      h.merge(part.id => { 'filter_id' => part.filter_id, 
                           'name' => part.name,
                           'part_type_name' => part.part_type.name,
                           'description' => part.description })
    end
    hash['layout_name'] = self.layout.name
    filename = self.filename.sub(/\.\w+$/, ".yaml")
    File.open(filename, 'w') {|f| f.write YAML.dump(hash)}
  end
  
  def layout_name=(name)
    self.layout = Layout.find_by_name(name)
  end
end
