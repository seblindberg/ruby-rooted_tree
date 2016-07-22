require 'test_helper'

describe RootedTree::Node do
  subject { RootedTree::Node }

  let(:root) { subject.new }
  let(:child) { subject.new }
  let(:child_a) { subject.new }
  let(:child_b) { subject.new }
  let(:child_c) { subject.new }

  describe '#leaf?' do
    it 'returns true for leaf nodes' do
      assert root.leaf?
    end

    it 'returns false for internal nodes' do
      root << child
      refute root.leaf?
      assert child.leaf?
    end
  end

  describe '#internal?' do
    it 'returns false for leaf nodes' do
      refute root.internal?
    end

    it 'returns true for interal nodes' do
      root << child
      assert root.internal?
      refute child.internal?
    end
  end

  describe '#root?' do
    it 'returns true for root nodes' do
      assert root.root?
    end

    it 'returns false for child nodes' do
      root << child
      refute child.root?
    end
  end

  describe '#root' do
    it 'returns the node itself if it is a root' do
      assert_same root, root.root
    end

    it 'returns the root of the tree' do
      root << child
      assert_same root, child.root
    end
  end

  describe '#first?' do
    it 'returns true for the first child' do
      root << child
      assert child.first?
    end

    it 'returns false for a child that is not first' do
      root << subject.new << child
      refute child.first?
    end
  end

  describe '#last?' do
    it 'returns true for the last child' do
      root << child
      assert child.last?
    end

    it 'returns false for a child that is not last' do
      root << child << subject.new
      refute child.last?
    end
  end

  describe '#depth' do
    it 'returns 0 for the root' do
      assert_equal 0, root.depth
    end

    it 'returns 1 for children to the root' do
      root << child
      assert_equal 1, child.depth
    end

    it 'returns the correct depth' do
      root << (child_a << (child_b << child_c))
      assert_equal 3, child_c.depth
    end
  end

  describe '#degree' do
    it 'reports 0 for leafs' do
      assert child.leaf?
      assert_equal 0, child.degree
    end

    it 'returns the number of children' do
      root << child_a << (child_b << child_c)
      assert_equal 2, root.degree
    end
  end

  describe '#size' do
    it 'returns 1 for leafs' do
      assert_equal 1, root.size
    end

    it 'returns the size of the subtree' do
      root << child_a << (child_b << child_c)
      assert_equal 4, root.size
    end
  end

  describe '#next' do
    it 'raises a StopIteration when there are no children' do
      assert_raises(StopIteration) { root.next }
    end

    it 'returns the next node' do
      root << child_a << child_b

      assert_same child_b, child_a.next
    end

    it 'raises a StopIteration at the last child' do
      root << child
      assert_raises(StopIteration) { child.next }
    end
  end

  describe '#prev' do
    it 'raises a StopIteration when there are no children' do
      assert_raises(StopIteration) { root.prev }
    end

    it 'returns the previous node' do
      root << child_a << child_b
      assert_same child_a, child_b.prev
    end

    it 'raises a StopIteration at the first child' do
      root << child
      assert_raises(StopIteration) { child.prev }
    end
  end

  describe '#parent' do
    it 'raises a StopIteration at the root' do
      assert_raises(StopIteration) { root.parent }
    end

    it 'returns the parent at a child' do
      root << child
      assert_same root, child.parent
    end
  end

  describe '#append_sibling' do
    it 'inserts a sibbling after a node' do
      root << child_a

      child_a.append_sibling child_b

      assert_same child_a, child_b.prev
      assert_same child_b, child_a.next
      assert_same root, child_b.parent
      assert_same child_b, root.last_child
    end

    it 'inserts a sibbling between two nodes' do
      root << child_a << child_c

      child_a.append_sibling child_b

      assert_same child_b, child_c.prev
      assert_same child_c, child_b.next
      assert_same child_c, root.last_child
    end

    it 'raises an exception when adding siblings to root nodes' do
      assert_raises(RootedTree::StructureException) do
        root.append_sibling subject.new
      end
    end
  end

  describe '#prepend_sibling' do
    it 'inserts a sibbling before a node' do
      root << child_b

      child_b.prepend_sibling child_a

      assert_same child_a, child_b.prev
      assert_same child_b, child_a.next
      assert_same root, child_a.parent
      assert_same child_a, root.first_child
    end

    it 'inserts a sibbling between two nodes' do
      root << child_a << child_c

      child_c.prepend_sibling child_b

      assert_same child_a, child_b.prev
      assert_same child_b, child_a.next
      assert_same child_a, root.first_child
    end

    it 'raises an exception when adding siblings to root nodes' do
      assert_raises(RootedTree::StructureException) do
        root.prepend_sibling subject.new
      end
    end
  end

  describe '#append_child' do
    it 'inserts a child under a childless root' do
      root.append_child child

      assert_same child, root.first_child
      assert_same child, root.last_child
      assert_same root, child.parent
    end

    it 'inserts a child after the other children' do
      root.append_child child_a
      root.append_child child_b

      assert_same child_a, root.first_child
      assert_same child_b, root.last_child
      assert_same child_b, child_a.next
      assert_same child_a, child_b.prev
    end
  end

  describe '#prepend_child' do
    it 'inserts a child under a childless root' do
      root.prepend_child child

      assert_same child, root.first_child
      assert_same child, root.last_child
      assert_same root, child.parent
    end

    it 'inserts a child before the other children' do
      root.prepend_child child_b
      root.prepend_child child_a

      assert_same child_a, root.first_child
      assert_same child_b, root.last_child
      assert_same child_b, child_a.next
      assert_same child_a, child_b.prev
    end
  end

  describe '#subtree!' do
    it 'extracts the subtree from the larger structure' do
      root << (child_a << child_b) << child_c

      subtree = child_a.subtree!

      assert subtree.root?
      assert_same child_b, subtree.children.next

      assert_same child_c, root.children.next
      assert_raises(StopIteration) { child_c.prev }
    end
  end

  describe '#delete' do
    it 'removes the middle child node from the tree' do
      root << child_a << child_b << child_c
      child_b.delete

      assert_same child_c, child_a.next
      assert_same child_a, child_c.prev
      assert child_b.root?
    end

    it 'removes the first child node from the tree' do
      root << child_a << child_b << child_c
      child_a.delete

      assert child_b.first?
      assert_same child_b, root.children.next
    end

    it 'removes the last child node from the tree' do
      root << child_a << child_b << child_c
      child_c.delete

      assert child_b.last?
      assert_same child_b, root.children(rtl: true).next
    end

    it 'returns an empty array when deleting leafs' do
      root << child_a
      assert_equal [], child_a.delete
      assert root.leaf?
    end

    it 'returns the children as subtrees' do
      root << child_a << child_b << child_c
      subtrees = root.delete
      assert_equal [child_a, child_b, child_c], subtrees
      assert child_a.root? && child_b.root? && child_c.root?
    end
  end

  describe '#dup' do
    it 'duplicates the entire subtree' do
      root << (child_a << child_b) << child_c
      root_dup = root.dup

      refute_same root, root_dup

      enum = root.each
      enum_dup = root_dup.each

      loop { refute_same enum.next, enum_dup.next }
      assert_raises(StopIteration) { enum.next }

      root_dup.children { |v| assert_same root_dup, v.parent }
    end

    it 'creates a separate subtree' do
      root << (child_a << child_b) << child_c
      child_a_dup = child_a.dup

      refute child_a.root?
      assert child_a_dup.root?
    end
  end

  describe '#ancestors' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, root.ancestors
    end

    it 'enumerates over nothing for the root' do
      assert_raises(StopIteration) { root.ancestors.next }
    end

    it 'enumerates over the ancestors' do
      root << (child_a << child_b)
      enum = child_b.ancestors

      assert_same child_a, enum.next
      assert_same root, enum.next
      assert_raises(StopIteration) { enum.next }
    end
  end

  describe '#children' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, root.children
    end

    it 'enumerates over nothing for a leaf' do
      assert_raises(StopIteration) { root.children.next }
    end

    it 'enumerates over the children left to right' do
      root << child_a << child_b
      enum = root.children

      assert_same child_a, enum.next
      assert_same child_b, enum.next
      assert_raises(StopIteration) { enum.next }
    end

    it 'enumerates over the children right to left' do
      root << child_a << child_b
      enum = root.children rtl: true

      assert_same child_b, enum.next
      assert_same child_a, enum.next
      assert_raises(StopIteration) { enum.next }
    end
  end

  describe '#each' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, root.each
    end

    it 'iterates over the node itself for a leaf' do
      enum = root.each
      assert_same root, enum.next
      assert_raises(StopIteration) { enum.next }
    end

    it 'iterates over the nodes' do
      root << (child_a << child_c) << child_b
      enum = root.each

      assert_same root, enum.next
      assert_same child_a, enum.next
      assert_same child_c, enum.next
      assert_same child_b, enum.next
      assert_raises(StopIteration) { enum.next }
    end
  end

  describe '#leafs' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, root.leafs
    end

    it 'iterates over the node itself for a leaf' do
      enum = root.leafs
      assert_same root, enum.next
      assert_raises(StopIteration) { enum.next }
    end

    it 'iterates over the leafs of the tree left to right' do
      root << (child_a << child_c) << child_b
      enum = root.leafs

      assert_same child_c, enum.next
      assert_same child_b, enum.next
      assert_raises(StopIteration) { enum.next }
    end

    it 'iterates over the leafs of the tree right to left' do
      root << (child_a << child_c) << child_b
      enum = root.leafs rtl: true

      assert_same child_b, enum.next
      assert_same child_c, enum.next
      assert_raises(StopIteration) { enum.next }
    end
  end

  describe '#edges' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, root.edges
    end

    it 'iterates over the edges' do
      root << (child_a << child_c) << child_b
      enum = root.edges

      assert_equal [root, child_a], enum.next
      assert_equal [child_a, child_c], enum.next
      assert_equal [root, child_b], enum.next

      assert_raises(StopIteration) { enum.next }
    end
  end

  describe '#==' do
    it 'returns false for other objects' do
      refute_operator root, :==, nil
      refute_operator root, :==, Object.new
    end

    it 'returns true for leafs' do
      assert_equal child_a, child_b
    end

    it 'returns true for nodes with identical subtrees' do
      child_a << subject.new << subject.new
      child_b << subject.new << subject.new

      assert_equal child_a, child_b
    end

    it 'returns false when the left hand side has more children' do
      child_a << subject.new << subject.new
      child_b << subject.new

      refute_operator child_a, :==, child_b
    end

    it 'returns false when the right hand side has more children' do
      child_a << subject.new
      child_b << subject.new << subject.new

      refute_operator child_a, :==, child_b
    end

    it 'returns false for nodes with different subtrees' do
      root << (child_a << subject.new)
      child_b << (subject.new << subject.new)

      refute_equal child_a, child_b
    end
  end

  describe '#+' do
    it 'adds two trees together under a new root' do
      parent = child_a + child_b
      enum = parent.children
      assert_same child_a, enum.next
      assert_same child_b, enum.next
    end

    it 'fails to add nodes that are not roots' do
      root << child_a
      assert_raises(RootedTree::StructureException) { child_a + child_b }
    end
  end

  describe '#inspect' do
    it 'accepts a block for labeling' do
      root << child_a << child_b
      child_a << child_c
      label = 'a'
      res = root.inspect do |_|
        (_, label = label, label.next).first
      end

      assert_equal "a\n├─╴b\n│  └─╴c\n└─╴d", res
    end
  end
end
