require 'test_helper'

describe RootedTree::Node do
  subject { RootedTree::Node }

  let(:root) { subject.new }
  let(:child) { subject.new }
  let(:child_a) { subject.new }
  let(:child_b) { subject.new }
  let(:child_c) { subject.new }

  describe '.new' do
    it 'accepts no arguments' do
      assert_silent { subject.new }
    end

    it 'accepts a value' do
      node = subject.new :value
      assert_equal :value, node.value
    end
  end

  describe '.[]' do
    it 'accepts no arguments' do
      assert_kind_of subject, subject[]
    end

    it 'does nothing when given a node' do
      assert_same root, subject[root]
    end

    it 'wraps the argument in a node' do
      assert_equal :value, subject[:value].value
    end
  end

  describe '#value' do
    it 'stores a value' do
      root.value = :value
      assert_equal :value, root.value
    end
  end

  describe '#freeze' do
    it 'makes the node immutable' do
      root.freeze
      assert_raises(RuntimeError) { root << child }
    end

    it 'freezes the children' do
      root << child
      root.freeze
      assert child.frozen?
    end

    it 'freezes the value' do
      root << child
      root.value = 'root'
      child.value = 'child'
      root.freeze

      assert root.value.frozen?
      assert child.value.frozen?
    end
  end

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
    it 'returns 0 for single nodes' do
      assert_equal 0, root.degree
    end

    it 'returns the number of children for roots' do
      root << child_a << (child_b << child_c)
      assert_equal 2, root.degree
    end

    it 'returns the number of children for internal nodes' do
      root << (child_a << child_b << child_c)
      assert_equal 2, child_a.degree
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

    it 'creates a node when given no argument' do
      root << child
      child.append_sibling
      assert_equal 2, root.degree
    end

    it 'wraps the argument in a node when given an object' do
      root << child
      child.append_sibling :value
      assert_equal :value, child.next.value
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

    it 'creates a node when given no argument' do
      root << child
      child.prepend_sibling
      assert_equal 2, root.degree
    end

    it 'wraps the argument in a node when given an object' do
      root << child
      child.prepend_sibling :value
      assert_equal :value, child.prev.value
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

    it 'creates a node when given no argument' do
      root.append_child
      assert_equal 1, root.degree
    end

    it 'wraps the argument in a node when given an object' do
      root.append_child :value
      assert_equal :value, root.child.value
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

    it 'creates a node when given no argument' do
      root.prepend_child
      assert_equal 1, root.degree
    end

    it 'wraps the argument in a node when given an object' do
      root.prepend_child :value
      assert_equal :value, root.child.value
    end
  end

  describe '#extract' do
    it 'extracts the node from the larger structure' do
      root << (child_a << child_b) << child_c

      subtree = child_a.extract

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

  describe '#child' do
    it 'returns the n:th child' do
      root << child_a << child_b

      assert_same child_a, root.child(0)
      assert_same child_b, root.child(1)
    end

    it 'reverses the order with a negative argument' do
      root << child_a << child_b

      assert_same child_b, root.child(-1)
      assert_same child_a, root.child(-2)
    end

    it 'raises a RangeError when index is out of range' do
      root << child_a << child_b
      assert_raises(RangeError) { root.child(2) }
    end

    it 'allows for single child access' do
      root << child
      assert_same child, root.child
    end

    it 'raises an ArgumentError with no argument for nodes with degree > 1' do
      root << child_a << child_b
      assert_raises(ArgumentError) { root.child }
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
    it 'fails to add nodes that are not roots' do
      root << child_a
      assert_raises(RootedTree::StructureException) { child_a + child_b }
    end
      
    it 'adds two trees together under a new root' do
      parent = child_a + child_b
      
      assert_same child_a, parent.child(0)
      assert_same child_b, parent.child(1)
    end
    
    it 'copies the nodes if they are frozen' do
      child_a.freeze
      child_b.freeze
      
      parent = child_a + child_b
      
      refute_same child_a, parent.child(0)
      refute_same child_b, parent.child(1)
    end
  end

  describe '#tree!' do
    it 'wraps the root node in a Tree and freezes it' do
      tree = root.tree!

      assert_kind_of RootedTree::Tree, tree
      assert_same root, tree.root
      assert root.frozen?
    end

    it 'always wraps the whole tree' do
      root << child
      tree = child.tree!
      assert_same root, tree.root
    end
  end

  describe '#tree' do
    it 'wraps an immutable copy of the root node in a Tree' do
      tree = root.tree

      assert_kind_of RootedTree::Tree, tree
      assert_equal root, tree.root
      refute_same root, tree.root
      assert tree.root.frozen?
    end
  end

  describe '#subtree!' do
    it 'returns the entire tree when called on the root' do
      root << child
      tree = root.subtree!
      assert_kind_of RootedTree::Tree, tree
      assert_same root, tree.root
    end

    it 'destructivly extracts the child node and its children' do
      root << child_a << (child_b << child_c)
      tree = child_b.subtree!

      assert_kind_of RootedTree::Tree, tree
      assert_same child_b, tree.root
      assert_equal 1, root.degree
    end
  end

  describe '#subtree' do
    it 'it preserves the original tree' do
      root << child_a << (child_b << child_c)
      tree = child_b.subtree

      assert_kind_of RootedTree::Tree, tree
      refute_same child_b, tree.root
      assert_equal child_b, tree.root
      assert_equal 2, root.degree
    end
  end

  describe '#inspect' do
    it 'includes the class name and object id by default' do
      res = root.inspect
      assert_equal format('%s:0x%0x', subject.name, root.object_id), res
    end

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
