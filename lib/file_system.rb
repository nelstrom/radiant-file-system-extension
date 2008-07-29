module FileSystem
  MODELS = %w{Layout Snippet Page}

  class << self
    def activate
      MODELS.each do |model|
        begin
          model = model.constantize
          model.send :include, FileSystem::Model
          try_special_module(model)
        rescue LoadError, NameError
        end
      end
    end

    def try_special_module(model)
      begin
        specialized_module = "FileSystem::Model::#{model.name}Extensions".constantize
        model.send :include, specialized_module
      rescue
      end
    end
  end
  
end
