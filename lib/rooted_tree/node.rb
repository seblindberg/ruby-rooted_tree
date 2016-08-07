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
  class Node < Linked::Item
    include Linked::List

    alias degree count
    alias arity degree
    alias first_child first
    alias last_child last
    alias << push

    protected :first, :last, :each_item

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
    
    # Returns true if this node is a leaf. A leaf is a node with no children.

    def leaf?
      degree == 0
    end

    # Returns true if the node is internal, which is equivalent to it having
    # children.

    def internal?
      degree > 0
    end

    # Returns true if the node has no parent.

    def root?
      list.nil?
    end

    # Returns the root of the tree structure that the node is part of.

    def root
      return self if root?

      node = self
      loop { node = node.parent }
      node
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

    # Access the parent node. Raises a StopIteration if this node is the
    # root.
    #
    # Returns the parent node.

    def parent
      raise StopIteration if root?
      list
    end

    # Insert a child between this node and the one after it.
    #
    # Returns self.

    def append_sibling(value = nil)
      raise StructureException, 'Root node can not have siblings' if root?

      append value
      self
    end

    # Insert a child between this node and the one before it.
    #
    # Returns self.

    def prepend_sibling(value = nil)
      raise StructureException, 'Root node can not have siblings' if root?

      prepend value
      self
    end

    # Insert a child after the last one.
    #
    # Returns self.

    def append_child(value = nil)
      push value
    end

    # Insert a child before the first one.
    #
    # Returns self.

    def prepend_child(value = nil)
      unshift value
    end

    # Extracts the node and its subtree from the larger structure.
    #
    # Returns self, now made root.

    def extract
      return self if root?

      method(:delete).super_method.call
      self
    end

    # Removes the node from the tree.
    #
    # Returns an array of the children to the deleted node, now made roots.

    def delete
      extract.children.to_a.each(&:extract)
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

    def children(rtl: false, &block)
      each_item(reverse: rtl, &block)
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
        if degree != 1
          raise ArgumentError, 'No argument given for node with degree != 1'
        end
        return first
      end

      rtl = if n < 0
              n = -1 - n
              true
            else
              false
            end

      raise RangeError, 'Child index out of range' if n >= degree

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
      return each.to_a if flatten
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
  end
end
