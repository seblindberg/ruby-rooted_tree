# frozen_string_literal: true

# Node
#
# Nodes are mutable by default, since creating anyting but simple leafs would
# otherwise be imposible. Calling #freeze on a node makes the entire subtree
# immutable. This is used by the Tree class which only operates on frozen node
# structures.
#
# The following is an example of a rooted tree with maximum depth 2.
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
    include Enumerable

    attr_accessor :first_child, :last_child, :degree, :value
    attr_writer :next, :prev, :parent

    protected :next=, :prev=, :parent=, :first_child=, :last_child=, :degree=

    alias arity degree

    def self.[](value = nil)
      return value if value.is_a? self
      self.new value
    end

    def initialize value = nil
      @parent = nil
      @next = nil
      @prev = nil
      @first_child = nil
      @last_child = nil
      @degree = 0
      @value = value
    end

    def initialize_copy(*)
      duped_children = children.map { |v| v.dup.tap { |w| w.parent = self } }
      duped_children.each_cons(2) { |a, b| a.next, b.prev = b, a }

      @parent = nil
      @first_child = duped_children.first
      @last_child = duped_children.last
    end

    def freeze
      @value.freeze
      children.each(&:freeze)
      super
    end

    # Leaf?
    #
    # A node is a leaf if it has no children.

    def leaf?
      @degree == 0
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
      return self if root?

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

    # Max Depth
    #
    # Returns the maximum node depth under this node.

    def max_depth(offset = depth)
      return offset if leaf?

      children.map { |c| c.max_depth offset + 1 }.max
    end

    # Max Degree
    #
    # Returns the highest child count of the nodes in the subtree.

    def max_degree
      children.map(&:degree).push(degree).max
    end

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

    def append_sibling(value = nil)
      raise StructureException, 'Root node can not have siblings' if root?

      node = self.class[value]
      node.next = @next
      node.prev = self
      node.parent = @parent
      @parent.degree += 1

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

    def prepend_sibling(value = nil)
      raise StructureException, 'Root node can not have siblings' if root?

      node = self.class[value]
      node.next = self
      node.prev = @prev
      node.parent = @parent
      @parent.degree += 1

      if @prev
        @prev.next = node
      else
        @parent.first_child = node
      end
      @prev = node
    end

    private def add_child_to_leaf(value)
      node = self.class[value]
      @first_child = @last_child = node
      node.next = node.prev = nil
      @degree = 1
      node.parent = self
    end

    # Append Child
    #
    # Insert a child after the last one.

    def append_child(value = nil)
      if leaf?
        add_child_to_leaf value
      else
        @last_child.append_sibling value
      end
      self
    end

    alias << append_child

    # Prepend Child
    #
    # Insert a child before the first one.

    def prepend_child(value = nil)
      if leaf?
        add_child_to_leaf value
      else
        @first_child.prepend_sibling value
      end
    end

    # Extract
    #
    # Extracts the node and its subtree from the larger structure.

    def extract
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

      @parent.degree -= 1
      @prev = @next = @parent = nil
      self
    end

    # Delete
    #
    # Removes the node from the tree.

    def delete
      extract.children.map do |child|
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
    # Yields to each of the node children. The default order is left-to-right,
    # but by passing rtl: true the order can be reversed. If a block is not
    # given an enumerator is returned.
    #
    # Note that the block will catch any StopIteration that is raised and
    # terminate early, returning the value of the exception.

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

    # Child
    #
    # Accessor method for any of the n children under this node.

    def child(n = nil)
      if n.nil?
        if @degree != 1
          raise ArgumentError, 'No argument given for node with degree != 1'
        end
        return @first_child
      end

      rtl = if n < 0
              n = -1 - n
              true
            else
              false
            end

      raise RangeError, 'Child index out of range' if n >= @degree

      children(rtl: rtl).each do |c|
        break c if n == 0
        n -= 1
      end
    end

    # Each
    #
    # Yields first to self and then to each child. If a block is not given an
    # enumerator is returned.

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
      return false unless degree == other.degree

      children.to_a == other.children.to_a
    end

    # Tree!
    #
    # Wraps the entire tree in a Tree object. The operation will freeze the node
    # structure, making it immutable. If this node is a child the root will be
    # found and passed to Tree.new.

    def tree!
      Tree.new root
    end

    # Tree
    #
    # Duplicates the entire tree and calls #tree! on the copy.

    def tree
      root.dup.tree!
    end

    # Subtree!
    #
    # Extracts this node from the larger tree and wraps it in a Tree object.

    def subtree!
      Tree.new extract
    end

    # Subtree
    #
    # Duplicates this node and its descendants and wraps them in a Tree object.

    def subtree
      Tree.new dup
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
    #   +--Node:0x3ffd64c1f40c
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
