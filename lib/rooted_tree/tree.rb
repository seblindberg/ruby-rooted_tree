# frozen_string_literal: true

module RootedTree
  module Tree
    # attr_reader :root
    #
    # def initialize(node)
    #   @root = node.root
    #   @root.freeze
    # end
    #
    # def tree
    #   self
    # end

    # Returns the maximum degree (highest number of children) in the tree.

    def degree
      @degree ||= root.max_degree
    end

    # Returns the maximum depth of the tree.

    def depth
      @depth ||= root.max_depth
    end
    
    def each_node(&block)
      @root.each(&block)
    end
    
    def each_leaf(&block)
      @root.leafs(&block)
    end
    
    def each_edge(&block)
      @root.edges(&block)
    end
  end
end
