# frozen_string_literal: true

# Node
#
#
# The following is an example of a rooted tree of height 3.
#
#       r         - r, a, b, c, and d are internal vertices
#    +--+---+     - vertices e, f, g, h, i, and j are leaves
#    a  b   c     - vertices g, h, and i are siblings
#   +++ | +-+-+   - node a is an ancestor of j
#   d e f g h i   - j is a descendant of a
#   |
#   j
#
# The terminology is mostly referenced from
# http://www.cs.columbia.edu/~cs4203/files/GT-Lec4.pdf.

module RootedTree
  class Node
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

    def initialize_copy(*)
      duped_children = children.map { |v| v.dup.tap { |w| w.parent = self } }
      duped_children.each_cons(2) { |a, b| a.next, b.prev = b, a }

      @parent = nil
      @first_child = duped_children.first
      @last_child = duped_children.last
    end

    # Leaf?
    #
    # A node is a leaf if it has no children.

    def leaf?
      @first_child.nil?
    end

    # Internal?
    #
    # Returns true if the node is internal, which is equivalent to it having
    # children.

    def internal?
      !leaf?
    end

    # Root?
    #
    # Returns true if node has no parent.

    def root?
      @parent.nil?
    end

    # Root
    #
    # Returns the root of the tree.

    def root
      node = self
      loop { node = node.parent }
      node
    end

    # First?
    #
    # Returns true if this node is the first of its siblings.

    def first?
      @prev.nil?
    end

    # Last?
    #
    # Returns true if this node is the last of its siblings.

    def last?
      @next.nil?
    end

    # Depth
    #
    # Returns the depth of the node within the tree

    def depth
      ancestors.count
    end

    alias level depth

    # Degree
    #
    # Returns the number of children of the node.

    def degree
      children.count
    end
    
    alias arity degree

    # Size
    #
    # Calculate the size in vertecies of the subtree.

    def size
      children.reduce(1) { |a, e| a + e.size }
    end

    # Next
    #
    # Access the next sibling. Raises a StopIteration if this node is the last
    # one.

    def next
      raise StopIteration if last?
      @next
    end

    # Prev(ious)
    #
    # Access the previous sibling. Raises a StopIteration if this node is the
    # first one.

    def prev
      raise StopIteration if first?
      @prev
    end

    alias previous prev

    # Parent
    #
    # Access the parent node. Raises a StopIteration if this node is the
    # root.

    def parent
      raise StopIteration if root?
      @parent
    end

    # Append Sibling
    #
    # Insert a child between this node and the one after it.

    def append_sibling(node)
      raise StructureException, 'Root node can not have siblings' if root?

      node.next = @next
      node.prev = self
      node.parent = @parent
      if @next
        @next.prev = node
      else
        @parent.last_child = node
      end
      @next = node
    end

    # Prepend Sibling
    #
    # Insert a child between this node and the one before it.

    def prepend_sibling(node)
      raise StructureException, 'Root node can not have siblings' if root?

      node.next = self
      node.prev = @prev
      node.parent = @parent
      if @prev
        @prev.next = node
      else
        @parent.first_child = node
      end
      @prev = node
    end

    # Append Child
    #
    # Insert a child after the last one.

    def append_child(child)
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

    alias << append_child

    # Subtree!
    #
    # Extracts the node and its subtree from the larger structure.

    def subtree!
      return self if root?

      if last?
        parent.last_child = @prev
      else
        @next.prev = @prev
      end

      if first?
        parent.first_child = @next
      else
        @prev.next = @next
      end

      @prev = @next = @parent = nil
      self
    end

    alias subtree dup

    # Delete
    #
    # Removes the node from the tree.

    def delete
      subtree!.children.map do |child|
        child.parent = nil
        child
      end
    end

    # Ancestors
    #
    # Returns an enumerator that will iterate over the parents of this node
    # until the root is reached.
    #
    # If a block is given it will be yielded to.

    def ancestors
      return to_enum(__callee__) unless block_given?
      node = self
      loop do
        node = node.parent
        yield node
      end
    end

    # Children
    #
    # Returns an enumerator that will iterate over each of the node children.
    # The default order is left-to-right, but by passing rtl: true the order can
    # be reversed.
    #
    # If a block is given it will be yielded to.

    def children(rtl: false)
      return to_enum(__callee__, rtl: rtl) unless block_given?
      return if leaf?

      child, advance = if rtl
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

    # Add
    #
    # Add two roots together to create a larger tree. A new common root will be
    # created and returned.

    def +(other)
      unless root? && other.root?
        raise StructureException, 'Only roots can be added'
      end

      root = self.class.new
      root << self << other
    end

    # Equality
    #
    # Returns true if the two vertecies form identical subtrees

    def ==(other)
      return false unless other.is_a? self.class
      return other.leaf? if leaf?

      children.to_a == other.children.to_a
    end

    # Inspect
    #
    # Visalizes the tree structure in a style very similar to the cli tool tree.
    # An example of the output can be seen below. Note that the output string
    # contains unicode characters.
    #
    #   Node:0x3ffd64c22abc
    #   |--Node:0x3ffd64c1fd30
    #   |  |--Node:0x3ffd64c1f86c
    #   |  +--Node:0x3ffd64c1f63c
    #   +--Entety:0x3ffd64c1f40c
    #
    # By passing `as_array: true` the method will instead return an array
    # containing each of the output lines. The method also accepts a block
    # which, if given, will be yielded to once for every node, and the output
    # will be used as node labels instead of the default identifier.

    def inspect(as_array: false, &block)
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
  end
end
