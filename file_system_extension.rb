# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class FileSystemExtension < Radiant::Extension
  version "0.1"
  description "Load Radiant models from the filesystem"
  url "http://github.com/nelstrom/radiant-file-system-extension/tree/master"
  
  def activate
    FileSystem.activate
  end
  
  def deactivate
    # admin.tabs.remove "File System"
  end

end
