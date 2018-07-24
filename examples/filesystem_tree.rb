#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rooted_tree'

# Maps the entries in the file system to `Node` objects via .map_to_path. The
# Node#inspect method is then exploited in #display to show the resulting tree
# structure. The name of each entry in the filesystem is stored in the value
# field of the Node.
class FileSystemItem < RootedTree::Node
  def display
    inspect(&:value)
  end

  def self.map_to_path(path = '.', root: new(path))
    # Iterate over all of the files in the directory
    Dir[path + '/*'].each do |entry|
      # Create a new FileSystemItem for the entry
      item = new File.basename(entry)
      root << item
      # Continue to map the files and directories under
      # entry, if it is a directory
      map_to_path entry, root: item unless File.file? entry
    end

    root
  end
end

puts FileSystemItem.map_to_path('.').display
