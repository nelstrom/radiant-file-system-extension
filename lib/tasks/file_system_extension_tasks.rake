namespace :file_system do
  
  def file_system_models
    require "#{RAILS_ROOT}/config/environment"
    FileSystem::MODELS.map{ |model| model.to_s.tableize.symbolize }
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
      task type => :environment do
        klass = type.to_s.singularize.classify.constantize
        if ENV['CLEAR'] == 'true' || ENV['WIPE'] == 'true'
          Rake::Task["file_system:wipe:#{type}"].invoke
        end
        klass.load_files
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
        klass.save_files
      end
    end
  end
end
