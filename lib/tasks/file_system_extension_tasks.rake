namespace :file_system do
  
  def file_system_models
    require "#{RAILS_ROOT}/config/environment"
    @file_system_models ||= FileSystem::MODELS.map{ |model| model.to_s.tableize.symbolize }
  end
  
  desc 'Loads all content models from the filesystem.'
  task :to_db => file_system_models.map {|m| "file_system:to_db:#{m}"}
  desc 'Destroys all content models in the database.'
  task :destroy_db => file_system_models.map {|m| "file_system:destroy_db:#{m}"}
  desc 'Saves all content models to the filesystem.'
  task :to_files => file_system_models.map {|m| "file_system:to_files:#{m}"}
  
  namespace :to_db do
    file_system_models.each do |type|
      desc "Loads all #{type} from the filesystem."
      task type => [:environment, "cache:clear"] do
        klass = type.to_s.singularize.classify.constantize
        if ENV['CLEAR'] == 'true' || ENV['WIPE'] == 'true'
          Rake::Task["file_system:wipe:#{type}"].invoke
        end
        klass.load_files if klass.respond_to?(:load_files)
      end
    end
  end

  namespace :destroy_db do
    file_system_models.each do |type|
      desc "Destroys all #{type} in the database."
      task type => :environment do
        klass = type.to_s.singularize.classify.constantize
        klass.destroy_all
      end
    end
  end
  
  namespace :to_files do
    file_system_models.each do |type|
      desc "Saves all #{type} in the database to the filesystem."
      task type => :environment do
        klass = type.to_s.singularize.classify.constantize
        klass.save_files if klass.respond_to?(:save_files)
      end
    end
  end
end

namespace :db do
  desc "Alias for file_system:to_files"
  task :to_fs => ["file_system:to_files"]
  
  namespace :to_fs do
    file_system_models.each do |type|
      task type => ["file_system:to_files:#{type}"]
    end
  end
end


namespace :fs do
  desc "Alias for file_system:to_db"
  task :to_db => ["file_system:to_db"]
  
  namespace :to_db do
    file_system_models.each do |type|
      task type => "file_system:to_db:#{type}"
    end
  end
end


namespace :cache do
  desc "Clear all files and directories in ./cache"
  task :clear do
    # todo: don't assume cache is in ./cache
    # fetch from @controller.page_cache_directory
    `rm -Rf cache/*`
  end
end
