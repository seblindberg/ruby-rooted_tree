# frozen_string_literal: true

# Tree
#
# Include this module in any object that responds to #root with a Node
# structure. The mixin provides some methods for describing the tree as well as
# direct access to some of the iteration methods in Node.

module RootedTree
  module Tree
    
    # Freezes the node structure that is part of the tree.
    
    def freeze
      root.freeze
      super
    end
    
    # Returns the maximum degree (highest number of children) in the tree.

    def degree
      root.max_degree
    end

    # Returns the maximum depth of the tree.

    def depth
      root.max_depth
    end

    # Iterates over each node in the tree. When given a block it will be yielded
    # to once for each node. If no block is given an enumerator is returned.

    def each_node(&block)
      root.each(&block)
    end

    # Iterates over each leaf in the tree. When given a block it will be yielded
    # to once for leaf node. If no block is given an enumerator is returned.

    def each_leaf(&block)
      root.leafs(&block)
    end

    # Iterates over each edge in the tree. An edge is composed of the parent
    # node and the child, always in that order. When given a block it will be
    # yielded to once for each node. If no block is given an enumerator is
    # returned.

    def each_edge(&block)
      root.edges(&block)
    end
  end
end
