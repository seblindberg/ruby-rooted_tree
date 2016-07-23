module RootedTree
  class Tree
    attr_reader :root
    
    def initialize(node = Node.new)
      @root = node.root
    end
    
    # Degree
    #
    # Returns the maximum degree (number of children) in the tree.
    
    def degree
      max_degree_node = root.each.max_by do |node|
        node.degree
      end
      max_degree_node.degree
    end
  end
end