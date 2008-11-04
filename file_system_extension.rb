class FileSystemExtension < Radiant::Extension
  version "0.2"
  description "Load Radiant models from the filesystem"
  url "http://github.com/nelstrom/radiant-file-system-extension/tree/master"
  
  def activate
    FileSystem.activate
  end
  
  def deactivate
    # admin.tabs.remove "File System"
  end

end
