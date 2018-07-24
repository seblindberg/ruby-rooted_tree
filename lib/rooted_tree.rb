# frozen_string_literal: true

require 'forwardable'
require 'linked'

require 'rooted_tree/version'
require 'rooted_tree/mutable'
require 'rooted_tree/node'
require 'rooted_tree/tree'

# A basic implementation of a tree data structure.
module RootedTree
  class StructureException < StandardError; end

  private_constant :Mutable
end
