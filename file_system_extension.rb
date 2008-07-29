# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class FileSystemExtension < Radiant::Extension
  version "0.1"
  description "Load Radiant models from the filesystem"
  url "http://code.digitalpulp.com"
  
  def activate
    FileSystem.activate
  end
  
  def deactivate
    # admin.tabs.remove "File System"
  end

end
