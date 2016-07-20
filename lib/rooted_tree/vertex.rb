# Vertex
#
#
# The following is an example of a rooted tree of height 3.
#
#       r         - r, a, b, c, and d are internal vertices
#    ┌──┼───┐     - vertices e, f, g, h, i, and j are leaves
#    a  b   c     - vertices g, h, and i are siblings
#   ┌┴┐ │ ┌─┼─┐   - vertex a is an ancestor of j
#   d e f g h i   - j is a descendant of a
#   │
#   j
#
# The terminology is mostly referenced from
# http://www.cs.columbia.edu/~cs4203/files/GT-Lec4.pdf.

module RootedTree
  class Vertex
    attr_accessor :first_child, :last_child
    attr_writer :next, :prev, :parent
    protected :next=, :prev=, :parent=, :first_child=, :last_child=
    
    def initialize
      @parent = nil
      @next = nil
      @prev = nil
      @first_child = nil
      @last_child = nil
    end
    
    # Leaf?
    #
    # A vertex is a leaf if it has no children.
    
    def leaf?
      @first_child.nil?
    end
    
    # Internal?
    #
    # Returns true if the vertex is internal, which is equivalent to it having
    # children.
    
    def internal?
      !leaf?
    end
    
    # Root?
    #
    # Returns true if vertex has no parent.
    
    def root?
      @parent.nil?
    end
    
    # First?
    #
    # Returns true if this vertex is the first of its siblings.
    
    def first?
      @prev.nil?
    end
    
    # Last?
    #
    # Returns true if this vertex is the last of its siblings.
    
    def last?
      @next.nil?
    end
    
    # Next
    #
    # Access the next sibling. Raises a StopIteration if this vertex is the last
    # one.
    
    def next
      raise StopIteration if last?
      @next
    end
    
    # Prev(ious)
    #
    # Access the previous sibling. Raises a StopIteration if this vertex is the
    # first one.
    
    def prev
      raise StopIteration if first?
      @prev
    end
    
    alias previous prev
    
    # Parent
    #
    # Access the parent vertex. Raises a StopIteration if this vertex is the
    # root.
    
    def parent
      raise StopIteration if root?
      @parent
    end
    
    # Append Sibling
    #
    # Insert a child between this vertex and the one after it.
    
    def append_sibling vertex
      raise StructureException, 'Root node can not have siblings' if root?
      
      vertex.next = @next
      vertex.prev = self
      vertex.parent = @parent
      if @next
        @next.prev = vertex
      else
        @parent.last_child = vertex
      end
      @next = vertex
    end
    
    # Prepend Sibling
    #
    # Insert a child between this vertex and the one before it.
    
    def prepend_sibling vertex
      raise StructureException, 'Root node can not have siblings' if root?
      
      vertex.next = self
      vertex.prev = @prev
      vertex.parent = @parent
      if @prev
        @prev.next = vertex
      else
        @parent.first_child = vertex
      end
      @prev = vertex
    end
    
    # Append Child
    #
    # Insert a child after the last one.
    
    def append_child child
      if leaf?
        @first_child = @last_child = child
        child.next = child.prev = nil
        child.parent = self
      else
        @last_child.append_sibling child
      end
      self
    end
    
    # Prepend Child
    #
    # Insert a child before the first one.
    
    def prepend_child(child)
      if leaf?
        @first_child = @last_child = child
        child.next = child.prev = nil
        child.parent = self
      else
        @first_child.prepend_sibling child
      end
    end
    
    
    alias :<< :append_child
    
    # Ancestors
    #
    # Returns an enumerator that will iterate over the parents of this vertex
    # until the root is reached.
    #
    # If a block is given it will be yielded to.
    
    def ancestors
      return to_enum(__callee__) unless block_given?
      vertex = self
      loop do
        vertex = vertex.parent
        yield vertex
      end
    end
    
    # Children
    #
    # Returns an enumerator that will iterate over each of the vertex children.
    # The default order is left-to-right, but by passing rtl: true the order can
    # be reversed.
    #
    # If a block is given it will be yielded to.
    
    def children(rtl: false)
      return to_enum(__callee__, rtl: rtl) unless block_given?
      return if leaf?
      
      child, advance =
        if rtl
          [@last_child, :prev]
        else
          [@first_child, :next]
        end
        
      loop do
        yield child
        child = child.send advance
      end
    end
    
    # Each
    #
    #
    
    def each(&block)
      return to_enum(__callee__) unless block_given?
      yield self
      children { |v| v.each(&block) }
    end
    
    # Leafs
    #
    # Iterates over each of the leafs.
    
    def leafs(rtl: false, &block)
      return to_enum(__callee__, rtl: rtl) unless block_given?
      return yield self if leaf?
      children(rtl: rtl) { |v| v.leafs(rtl: rtl, &block) }
    end
    
    # Edges
    #
    # Iterates over each of the edges.
    
    def edges(&block)
      return to_enum(__callee__) unless block_given?
      
      children do |v|
        yield self, v
        v.edges(&block)
      end
    end
    
    # Inspect
    #
    # Visalizes the tree structure in a style very similar to the cli tool tree.
    # An example of the output can be seen below. Note that the output string
    # contains unicode characters.
    #
    #   Vertex:0x3ffd64c22abc
    #   ├─╴Vertex:0x3ffd64c1fd30
    #   │  ├─╴Vertex:0x3ffd64c1f86c
    #   │  └─╴Vertex:0x3ffd64c1f63c
    #   └─╴Entety:0x3ffd64c1f40c
    #
    # By passing `as_array: true` the method will instead return an array
    # containing each of the output lines. The method also accepts a block
    # which, if given, will be yielded to once for every vertex, and the output
    # will be used as vertex labels instead of the default identifier.

    def inspect as_array: false, &block
      unless block_given?
        block = proc { |v| format '%s:0x%0x', v.class.name, v.object_id }
      end
      
      res = [block.call(self)]
      
      children do |child|
        lines = child.inspect(as_array: true, &block).each
        res << ((child.last? ? '└─╴' : '├─╴') + lines.next)
        prep = child.last? ? '   ' : '│  '
        loop { res << (prep + lines.next) }
      end
      
      as_array ? res : res.join("\n")
    end
    
    # Structure
    #
    #
    
    def structure as_array: false
      
    end
  end
end