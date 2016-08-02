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

    # Creates a new node with the given object as its value, unless a Node is
    # passed, in which case it will be returned.
    #
    # value - the object to be used as value for a new Node, or a Node object.
    #
    # Returns a Node object.

    def self.[](value = nil)
      return value if value.is_a? self
      new value
    end
    
    # Create a new, unconnected Node object with an optional value. The value is
    # owned by the Node instance and will be duped along with it.
    #
    # value - arbitrary object that is owned by the Node instance.

    def initialize(value = nil)
      @parent = nil
      @next = nil
      @prev = nil
      @first_child = nil
      @last_child = nil
      @degree = 0
      @value = value
    end
    
    # When copying a node the child nodes are copied as well, along with the
    # value.

    def initialize_dup(original)
      # Dup each child and link them to the new parent
      duped_children = original.children.map do |child|
        child.dup.tap { |n| n.parent = self }
      end
      
      # Connect each child to its adjecent siblings
      duped_children.each_cons(2) { |a, b| a.next, b.prev = b, a }

      @parent = nil
      @first_child = duped_children.first
      @last_child = duped_children.last
      @value = begin
                 original.value.dup
               rescue TypeError
                 original.value
               end
    end

    def freeze
      @value.freeze
      children.each(&:freeze)
      super
    end

    # Returns true if this node is a leaf. A leaf is a node with no children.

    def leaf?
      @degree == 0
    end

    # Returns true if the node is internal, which is equivalent to it having
    # children.

    def internal?
      !leaf?
    end

    # Returns true if the node has no parent.

    def root?
      @parent.nil?
    end

    # Returns the root of the tree structure that the node is part of.

    def root
      return self if root?

      node = self
      loop { node = node.parent }
      node
    end

    # Returns true if this node is the first of its siblings.

    def first?
      @prev.nil?
    end

    # Returns true if this node is the last of its siblings.

    def last?
      @next.nil?
    end

    # Returns the depth of the node within the tree

    def depth
      ancestors.count
    end

    alias level depth

    # Returns the maximum node depth under this node.

    def max_depth(offset = depth)
      return offset if leaf?

      children.map { |c| c.max_depth offset + 1 }.max
    end

    # Returns the highest child count of the nodes in the subtree.

    def max_degree
      children.map(&:degree).push(degree).max
    end

    # Calculate the size in vertecies of the subtree.
    #
    # Returns the number of nodes under this node, including self.

    def size
      children.reduce(1) { |a, e| a + e.size }
    end

    # Access the next sibling. Raises a StopIteration if this node is the last
    # one.
    #
    # Returns the previous sibling node.

    def next
      raise StopIteration if last?
      @next
    end

    # Access the previous sibling. Raises a StopIteration if this node is the
    # first one.
    #
    # Returns the previous sibling node.

    def prev
      raise StopIteration if first?
      @prev
    end

    alias previous prev

    # Access the parent node. Raises a StopIteration if this node is the
    # root.
    #
    # Returns the parent node.

    def parent
      raise StopIteration if root?
      @parent
    end

    # Insert a child between this node and the one after it.
    #
    # Returns self.

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

    # Insert a child between this node and the one before it.
    #
    # Returns self.

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

    # Insert a child after the last one.
    #
    # Returns self.

    def append_child(value = nil)
      if leaf?
        add_child_to_leaf value
      else
        @last_child.append_sibling value
      end
      self
    end

    alias << append_child

    # Insert a child before the first one.
    #
    # Returns self.

    def prepend_child(value = nil)
      if leaf?
        add_child_to_leaf value
      else
        @first_child.prepend_sibling value
      end
    end

    # Extracts the node and its subtree from the larger structure.
    #
    # Returns self, now made root.

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

    # Removes the node from the tree.
    #
    # Returns an array of the children to the deleted node, now made roots.

    def delete
      extract.children.map do |child|
        child.parent = nil
        child
      end
    end

    # Iterates over the nodes above this in the tree hierarchy and yields them
    # to a block. If no block is given an enumerator is returned.
    #
    # Returns an enumerator that will iterate over the parents of this node
    # until the root is reached.

    def ancestors
      return to_enum(__callee__) unless block_given?
      node = self
      loop do
        node = node.parent
        yield node
      end
    end

    # Yields each of the node children. The default order is left-to-right, but
    # by passing rtl: true the order is reversed. If a block is not given an
    # enumerator is returned.
    #
    # Note that the block will catch any StopIteration that is raised and
    # terminate early, returning the value of the exception.
    #
    # rtl - reverses the iteration order if true.

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

    # Accessor method for any of the n children under this node. If called
    # without an argument and the node has anything but exactly one child an
    # exception will be raised.
    #
    # n - the n:th child to be returned. If n is negative the indexing will be
    #     reversed and the children counted from the last to the first.
    #
    # Returns the child at the n:th index.

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

    # Yields first to self and then to each child. If a block is not given an
    # enumerator is returned.

    def each(&block)
      return to_enum(__callee__) unless block_given?
      yield self
      children { |v| v.each(&block) }
    end

    # Converts the tree structure to a nested array of the nodes. Each internal
    # node is placed at index zero of its own array, followed by an array of its
    # children. Leaf nodes are not wraped in arrays but inserted directly.
    #
    # flatten - flattens the array if true.
    #
    # Example
    #
    #     r
    #    / \
    #   a   b  => [r, [[a, [c]], b]]
    #   |
    #   c
    #
    # Returns a nested array of nodes.

    def to_a flatten: false
      return super() if flatten
      return self if leaf?
      [self, children.map(&:to_a)]
    end

    # Iterates over each of the leafs.
    #
    # rtl - if true the iteration order is switched to right to left.

    def leafs(rtl: false, &block)
      return to_enum(__callee__, rtl: rtl) unless block_given?
      return yield self if leaf?
      children(rtl: rtl) { |v| v.leafs(rtl: rtl, &block) }
    end

    # Iterates over each of the edges and yields the parent and the child. If no
    # block is given an enumerator is returned.
    #
    # block - an optional block that will be yielded to, if given.

    def edges(&block)
      return to_enum(__callee__) unless block_given?

      children do |v|
        yield self, v
        v.edges(&block)
      end
    end

    # Add two roots together to create a larger tree. A new common root will be
    # created and returned. Note that if the any of the root nodes are not
    # frozen they will be modified, and as a result seize to be roots.
    #
    # other - a Node-like object that responds true to #root?
    #
    # Returns a new root with the two nodes as children.

    def +(other)
      unless root? && other.root?
        raise StructureException, 'Only roots can be added'
      end

      a = frozen? ? dup : self
      b = other.frozen? ? other.dup : other

      ab = self.class.new
      ab << a << b
    end

    # Compare one node (sub)structure with another.
    #
    # Returns true if the two vertecies form identical subtrees

    def ==(other)
      return false unless other.is_a? self.class
      return false unless degree == other.degree
      return false unless value == other.value

      children.to_a == other.children.to_a
    end

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
