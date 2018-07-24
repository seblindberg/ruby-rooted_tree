# frozen_string_literal: true

module RootedTree
  # Include this module in any object that responds to #root with a Node
  # structure. The mixin provides some methods for describing the tree as well
  # as direct access to some of the iteration methods in Node.
  module Tree
    extend Forwardable

    # Freezes the node structure that is part of the tree.
    def freeze
      root.freeze
      super
    end

    # Returns the maximum degree (highest number of children) in the tree.
    def_delegator :root, :max_degree, :degree

    # Returns the maximum depth of the tree.
    def_delegator :root, :max_depth, :depth

    # Iterates over each node in the tree. When given a block it will be yielded
    # to once for each node. If no block is given an enumerator is returned.
    def_delegator :root, :each, :each_node

    # Iterates over each leaf in the tree. When given a block it will be yielded
    # to once for leaf node. If no block is given an enumerator is returned.
    def_delegator :root, :leafs, :each_leaf

    # Iterates over each edge in the tree. An edge is composed of the parent
    # node and the child, always in that order. When given a block it will be
    # yielded to once for each node. If no block is given an enumerator is
    # returned.
    def_delegator :root, :edges, :each_edge
  end
end
