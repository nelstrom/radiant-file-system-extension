module FileSystem::Model::PartTypeExtensions
  def content_type
    "text/x-yaml"
  end
  
  def content_type=(value)
  end
  
  def content
    attrs = self.attributes.dup
    attrs.delete('id')
    attrs.delete('name')
    attrs.to_yaml
  end
  
  def content=(yaml_text)
    self.attributes = YAML.load(yaml_text)
  end
end
