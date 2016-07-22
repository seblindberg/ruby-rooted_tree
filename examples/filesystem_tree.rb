#!/usr/bin/env ruby

require 'rooted_tree'

# FileSystemItem
#
# Maps the entries in the file system to `Node` objects via .map_to_path. The
# Node#inspect method is then exploited in #display to show the resulting tree
# structure.

class FileSystemItem < RootedTree::Node
  attr_reader :name
  
  def initialize name
    super()
    @name = name
  end
  
  def display
    inspect { |item| item.name }
  end
  
  def self.map_to_path path = '.', root: new(path)
    # Iterate over all of the files in the directory
    Dir[path + '/*'].each do |entry|
      # Create a new FileSystemItem for the entry
      item = new File.basename entry
      root << item
      # Continue to map the files and directories under
      # entry, if it is a directory
      map_to_path entry, root: item unless File.file? entry
    end
    
    root
  end
end

puts FileSystemItem.map_to_path('.').display
