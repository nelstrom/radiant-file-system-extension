module FileSystem
  module Model
    FILENAME_REGEX = /^(?:(\d+)_)?([^.]+)(?:\.([\-\w]+))?/
    CONTENT_TYPES = {"html" => "text/html", 
                     "css" => "text/css",
                     "xml" => "application/xml",
                     "rss" => "application/rss+xml",
                     "txt" => "text/plain",
                     "js" => "text/javascript",
                     "yaml" => "text/x-yaml"}
    FILTERS = %w{textile markdown smarty_pants}

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def klass_name
        @klass_name ||= class_of_active_record_descendant(self).name
      end
      
      def path
        File.join(RAILS_ROOT, "design",
          klass_name.pluralize.underscore)
      end

      def find_or_initialize_by_filename(filename)
        id = extract_id(filename)
        name = extract_name(filename)
        find_by_id(id) || find_by_name(name) || new
      end
      
      def find_existing_records
        klass_name.constantize.find(:all, :select => "id,name")
      end
      
      def delete_record(record)
        klass_name.constantize.destroy(record)
      end

      def load_files
        existing_records = find_existing_records
        puts "records: #{existing_records}"
        Dir[path + "/**"].each do |file|
          record = find_or_initialize_by_filename(file)
          puts "Loading #{self.name.downcase} from #{File.basename(file)}."
          record.load_file(file)
          record.save
          existing_records.delete(record)
        end
        # anything remaining in the existing_records array has no corresponding file
        # (but exists in DB), so we'll delete it.
        existing_records.each do |item|
          delete_record(item)
        end
        puts "records: #{existing_records}"
      end

      def save_files
        find(:all).each(&:save_file)
      end
      
      def extract_id(filename)
        basename = File.basename(filename)
        $1.to_i if basename =~ FILENAME_REGEX
      end
      
      def extract_name(filename)
        basename = File.basename(filename)
        $2 if basename =~ FILENAME_REGEX
      end
    end
   
    def load_file(file)
      name, type_or_filter = $2, $3 if File.basename(file) =~ FILENAME_REGEX
      content = open(file).read
      self.name = name
      self.content = content
      self.content_type = CONTENT_TYPES[type_or_filter] if respond_to?(:content_type)
      if respond_to?(:filter_id) 
        self.filter_id = FILTERS.include?(type_or_filter) ? type_or_filter.camelize : nil
      end
    end
    
    def save_file
      FileUtils.mkdir_p(File.dirname(self.filename)) unless File.directory?(File.dirname(self.filename))
      File.open(self.filename, "w") {|f| f.write self.content }
    end
    
    def filename
      @filename ||= returning String.new do |output|
        basename = self.name
        extension = case 
          when respond_to?(:filter_id)
            self.filter_id.blank? ? "html" : self.filter_id.downcase
          when respond_to?(:content_type)
            CONTENT_TYPES.invert[self.content_type] || "html"
          else
            "html"
        end
        output << File.join(self.class.path, [basename, extension].join("."))
      end
    end      
  end
end
