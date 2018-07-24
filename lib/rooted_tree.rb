# frozen_string_literal: true

require 'forwardable'
require 'linked'

require 'rooted_tree/version'
require 'rooted_tree/node'
require 'rooted_tree/tree'

module RootedTree
  class StructureException < StandardError; end
end
