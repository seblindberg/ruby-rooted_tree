# frozen_string_literal: true

module RootedTree
  # This module contains methods for mutating a tree node.
  module Mutable
    # Insert a child between this node and the one after it.
    #
    # @raise [StructureException] if this node has no parent.
    #
    # @param  value [Object] the value of the new sibling.
    # @return [self]
    def append_sibling(value = nil)
      raise StructureException, 'Root node can not have siblings' if root?

      append value
      self
    end

    # Insert a child between this node and the one before it.
    #
    # @raise [StructureException] if this node has no parent.
    #
    # @param  value [Object] the value of the new sibling.
    # @return [self]
    def prepend_sibling(value = nil)
      raise StructureException, 'Root node can not have siblings' if root?

      prepend value
      self
    end

    # Insert a child after the last one.
    #
    # @param  value [Object] the value of the new sibling.
    # @return [self]
    def append_child(value = nil)
      push value
    end

    # @see #append_child.
    alias << append_child

    # Insert a child before the first one.
    #
    # @param  value [Object] the value of the new sibling.
    # @return [self]
    def prepend_child(value = nil)
      unshift value
    end

    # Extracts the node and its subtree from the larger structure.
    #
    # @return [self] the node will now be root.
    def extract
      return self if root?

      method(:delete).super_method.call
      self
    end

    # Removes the node from the tree.
    #
    # @return [Array<Node>] an array of the children to the deleted node, now
    #   made roots.
    def delete
      extract.children.to_a.each(&:extract)
    end
  end
end
