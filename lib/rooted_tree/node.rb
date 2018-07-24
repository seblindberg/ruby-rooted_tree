# frozen_string_literal: true

module RootedTree
  # rubocop:disable Metrics/ClassLength

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
  class Node < Linked::Item
    extend  Forwardable
    include Linked::List
    include Mutable

    # Creates a new node with the given object as its value, unless a Node is
    # passed, in which case it will be returned.
    #
    # @param  value [Object] the object to be used as value for a new Node, or a
    #   Node object.
    # @return [Node] a Node object.
    def self.[](value = nil)
      return value if value.is_a? self
      new value
    end

    # @return [Integer] the number of children of the node.
    alias degree count

    # @return [Integer] see #degree.
    alias arity degree

    # @return [Node] the first child.
    alias first_child first

    # @return [Node] the last child.
    alias last_child last

    # @return [true] if this node has no children.
    # @return [false] otherwise.
    def_delegator :degree, :zero?, :leaf?

    # @return [true] if the node has children.
    # @return [false] otherwise.
    def_delegator :degree, :positive?, :internal?

    # @return [true] if the node has no parent.
    # @return [false] otherwise.
    def_delegator :list, :nil?, :root?

    # @return [Node] the root of the tree structure that the node is part of.
    def root
      return self if root?
      loop.reduce(self) { |node,| node.parent }
    end

    # @return [Integer] the depth of the node within the tree.
    def_delegator :ancestors, :count, :depth

    alias level depth

    # @return [Integer] the maximum node depth under this node.
    def max_depth(offset = depth)
      return offset if leaf?

      children.map { |c| c.max_depth offset + 1 }.max
    end

    # @return [Integer] the highest child count of the nodes in the subtree.
    def max_degree
      children.map(&:degree).push(degree).max
    end

    # Calculate the size in vertecies of the subtree.
    #
    # @return [Integer] the number of nodes under this node, including self.
    def size
      children.reduce(1) { |a, e| a + e.size }
    end

    # Access the parent node. Raises a StopIteration if this node is the
    # root.
    #
    # @raise [StopIteration] if this node is the root.
    #
    # @return [Node] the parent node.
    def parent
      raise StopIteration if root?
      list
    end

    # Iterates over the nodes above this in the tree hierarchy and yields them
    # to a block. If no block is given an enumerator is returned.
    #
    # @yield  [Node] each parent node.
    # @return [Enumerator] if no block is given.
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
    # @param  rtl [true, false] reverses the iteration order if true.
    # @return see #each_item
    def children(rtl: false, &block)
      rtl ? reverse_each_item(&block) : each_item(&block)
    end

    # Accessor method for any of the n children under this node. If called
    # without an argument and the node has anything but exactly one child an
    # exception will be raised.
    #
    # @param index [Integer] the n:th child to be returned. If the index is
    #   negative the indexing will be reversed and the children counted from the
    #   last to the first.
    # @return [Node] the child at the n:th index.
    def child(index = nil)
      unless index
        raise ArgumentError, 'No index for node with degree != 1' if degree != 1
        return first
      end

      rtl, index = wrap_index index

      raise RangeError, 'Child index out of range' if index >= degree

      children(rtl: rtl).each do |c|
        break c if index.zero?
        index -= 1
      end
    end

    alias [] child

    # @yield  [Node] first self is yielded and then the children who in turn
    #   yield their children.
    # @return [Enumerator] if no block is given.
    def each(&block)
      return to_enum(__callee__) unless block_given?
      yield self
      children { |v| v.each(&block) }
    end

    # Converts the tree structure to a nested array of the nodes. Each internal
    # node is placed at index zero of its own array, followed by an array of its
    # children. Leaf nodes are not wraped in arrays but inserted directly.
    #
    # == Example
    #
    #     r
    #    / \
    #   a   b  => [r, [[a, [c]], b]]
    #   |
    #   c
    #
    # @param  flatten [true, false] the array is flattened if true.
    # @return [Array<Node, Array>] a nested array of nodes.
    def to_a(flatten: false)
      return each.to_a if flatten
      return self if leaf?
      [self, children.map(&:to_a)]
    end

    # Iterates over each of the leafs.
    #
    # @param rtl [true, false] if true the iteration order is switched to right
    #   to left.
    def leafs(rtl: false, &block)
      return to_enum(__callee__, rtl: rtl) unless block_given?
      return yield self if leaf?
      children(rtl: rtl) { |v| v.leafs(rtl: rtl, &block) }
    end

    # Iterates over each edge in the tree.
    #
    # @yield  [Array<Node>] each connected node pair.
    # @return [Enumerator] if no block is given.
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
    # @param  other [Node] a Node-like object that responds true to #root?
    # @return [Node] a new root with the two nodes as children.
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
    # @param  other [Object]
    # @return [true] if the two vertecies form identical subtrees.
    # @reutrn [false] otherwise.
    def ==(other)
      return false unless other.is_a? self.class
      return false unless degree == other.degree
      return false unless value == other.value

      children.to_a == other.children.to_a
    end

    private

    def wrap_index(index)
      if index.negative?
        [true, -1 - index]
      else
        [false, index]
      end
    end

    protected :first, :last, :each_item
    private :push, :unshift, :list, :count
  end

  # rubocop:enable Metrics/ClassLength
end
