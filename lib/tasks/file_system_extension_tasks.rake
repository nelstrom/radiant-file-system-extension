namespace :radiant do
  namespace :extensions do
    namespace :file_system do
      
      desc "Runs the migration of the File System extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          FileSystemExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          FileSystemExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the File System to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[FileSystemExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(FileSystemExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end

namespace :file_system do
  desc 'Loads all content models from the filesystem.'
  task :load => [:layouts, :snippets, :part_types, :templates, :pages].map {|m| "file_system:load:#{m}"}
  desc 'Destroys all content models in the database.'
  task :wipe => [:layouts, :snippets, :part_types, :templates, :pages].map {|m| "file_system:wipe:#{m}"}
  desc 'Saves all content models to the filesystem.'
  task :save => [:layouts, :snippets, :part_types, :templates, :pages].map {|m| "file_system:save:#{m}"}
  
  namespace :load do
    [:layouts, :snippets, :part_types, :templates, :pages].each do |type|
      desc "Loads all #{type} from the filesystem."
      task type => :environment do
        klass = type.to_s.singularize.classify.constantize
        if ENV['CLEAR'] == 'true' || ENV['WIPE'] == 'true'
          Rake::Task["file_system:wipe:#{type}"].invoke
        end
        klass.load_files
      end
    end
  end

  namespace :wipe do
    [:layouts, :snippets, :part_types, :templates, :pages].each do |type|
      desc "Destroys all #{type} in the database."
      task type => :environment do
        klass = type.to_s.singularize.classify.constantize
        klass.destroy_all
      end
    end
  end
  
  namespace :save do
    [:layouts, :snippets, :part_types, :templates, :pages].each do |type|
      desc "Saves all #{type} in the database to the filesystem."
      task type => :environment do
        klass = type.to_s.singularize.classify.constantize
        klass.save_files
      end
    end
  end
end
