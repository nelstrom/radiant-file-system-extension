module FileSystem::Model::TextAssetExtensions
  # IGNORED = %w{id parent_id layout_id lock_version
  #             created_by created_at updated_by updated_at}
  
  def self.included(base)   
    # Instance methods
    base.class_eval do
      extend ClassMethods
      include InstanceMethods
      %w{load_file filename}.each do |m|
        alias_method_chain m.to_sym, :subfolder
      end 
    end
    # Singleton/class methods
    class << base
      %w{find_or_initialize_by_filename load_files}.each do |m|
        alias_method_chain m.to_sym, :subfolder
      end
    end
  end

  module ClassMethods

    def find_or_initialize_by_filename_with_subfolder(filename)
      name = File.basename(filename)
      class_name = $1 if File.dirname(filename) =~ /(?:(\w+))$/
      find_or_initialize_by_name_and_class_name(name, class_name)
    end

    @@text_assets_on_filesystem = []

    def register_text_asset_on_filesystem(text_asset)
      @@text_assets_on_filesystem << text_asset
    end

    def text_assets_on_database
      TextAsset.find(:all)
    end

    def delete_fileless_records_from_db
      fileless_text_asset_ids = text_assets_on_database.map(&:id) - @@text_assets_on_filesystem.map(&:id)
      fileless_text_asset_ids.each { |text_asset_id| TextAsset.destroy(text_asset_id) }
    end

    def load_files_with_subfolder
      javascripts.each do |t|
        text_asset = find_or_initialize_by_filename(t)
        text_asset.class_name = "Javascript"
        text_asset.load_file(t)
      end
      stylesheets.each do |t|
        text_asset = find_or_initialize_by_filename(t)
        text_asset.class_name = "Stylesheet"
        text_asset.load_file(t)
      end
      delete_fileless_records_from_db
    end

    def javascripts
      Dir[path + "/Javascript/*"]
    end

    def stylesheets
      Dir[path + "/Stylesheet/*"]
    end
  end

  module InstanceMethods
    def load_file_with_subfolder(path)
      class_and_file_name = path.sub(/#{self.class.path}\/\/?/, '/')
      puts "Loading text asset from #{class_and_file_name}"
      class_name = $1 if class_and_file_name =~ /^\/?(?:(\w+))\//
      self.class_name = class_name
      self.content = open(path).read
      save!
      self.class.register_text_asset_on_filesystem(self)
    end

    def filename_with_subfolder
      File.join([self.class.path, self.class_name, self.name].flatten)
    end

  end
end