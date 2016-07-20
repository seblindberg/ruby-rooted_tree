require 'test_helper'

describe RootedTree::Vertex do
  subject { RootedTree::Vertex }
  

  let(:root) { subject.new }
  let(:child) { subject.new }
  let(:child_a) { subject.new }
  let(:child_b) { subject.new }
  let(:child_c) { subject.new }
  
  describe '#leaf?' do
    it 'returns true for leaf vertecies' do
      assert root.leaf?
    end
    
    it 'returns false for internal vertecies' do
      root << child
      refute root.leaf?
      assert child.leaf?
    end
  end
  
  describe '#internal?' do
    it 'returns false for leaf vertecies' do
      refute root.internal?
    end
    
    it 'returns true for interal vertecies' do
      root << child
      assert root.internal?
      refute child.internal?
    end
  end
  
  describe '#root?' do
    it 'returns true for root vertecies' do
      assert root.root?
    end
    
    it 'returns false for child vertecies' do
      root << child
      refute child.root?
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
  
  describe '#next' do
    it 'raises a StopIteration when there are no children' do
      assert_raises(StopIteration) { root.next }
    end
    
    it 'returns the next vertex' do
      root << child_a << child_b
      
      assert_equal child_b, child_a.next
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
    
    it 'returns the previous vertex' do
      root << child_a << child_b
      assert_equal child_a, child_b.prev
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
      assert_equal root, child.parent
    end
  end
  
  describe '#append_sibling' do
    it 'inserts a sibbling after a vertex' do
      root << child_a
      
      child_a.append_sibling child_b
      
      assert_equal child_a, child_b.prev
      assert_equal child_b, child_a.next
      assert_equal root, child_b.parent
      assert_equal child_b, root.last_child
    end
    
    it 'inserts a sibbling between two vertecies' do
      root << child_a << child_c
      
      child_a.append_sibling child_b
      
      assert_equal child_b, child_c.prev
      assert_equal child_c, child_b.next
      assert_equal child_c, root.last_child
    end
    
    it 'raises an exception when adding siblings to root vertecies' do
      assert_raises(RootedTree::StructureException) {
        root.append_sibling subject.new }
    end
  end
  
  describe '#prepend_sibling' do
    it 'inserts a sibbling before a vertex' do
      root << child_b
      
      child_b.prepend_sibling child_a
      
      assert_equal child_a, child_b.prev
      assert_equal child_b, child_a.next
      assert_equal root, child_a.parent
      assert_equal child_a, root.first_child
    end
    
    it 'inserts a sibbling between two vertecies' do
      root << child_a << child_c
      
      child_c.prepend_sibling child_b
          
      assert_equal child_a, child_b.prev
      assert_equal child_b, child_a.next
      assert_equal child_a, root.first_child
    end
    
    it 'raises an exception when adding siblings to root vertecies' do
      assert_raises(RootedTree::StructureException) {
        root.prepend_sibling subject.new }
    end
  end
  
  describe '#append_child' do
    it 'inserts a child under a childless root' do
      root.append_child child
      
      assert_equal child, root.first_child
      assert_equal child, root.last_child
      assert_equal root, child.parent
    end
    
    it 'inserts a child after the other children' do
      root.append_child child_a
      root.append_child child_b
      
      assert_equal child_a, root.first_child
      assert_equal child_b, root.last_child
      assert_equal child_b, child_a.next
      assert_equal child_a, child_b.prev
    end
  end
  
  describe '#prepend_child' do
    it 'inserts a child under a childless root' do
      root.prepend_child child
      
      assert_equal child, root.first_child
      assert_equal child, root.last_child
      assert_equal root, child.parent
    end
    
    it 'inserts a child before the other children' do
      root.prepend_child child_b
      root.prepend_child child_a
      
      assert_equal child_a, root.first_child
      assert_equal child_b, root.last_child
      assert_equal child_b, child_a.next
      assert_equal child_a, child_b.prev
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
      
      assert_equal child_a, enum.next
      assert_equal root, enum.next
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
      
      assert_equal child_a, enum.next
      assert_equal child_b, enum.next
      assert_raises(StopIteration) { enum.next }
    end
    
    it 'enumerates over the children right to left' do
      root << child_a << child_b
      enum = root.children rtl: true
      
      assert_equal child_b, enum.next
      assert_equal child_a, enum.next
      assert_raises(StopIteration) { enum.next }
    end
  end
  
  describe '#each' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, root.each
    end
    
    it 'iterates over the vertex itself for a leaf' do
      enum = root.each
      assert_equal root, enum.next
      assert_raises(StopIteration) { enum.next }
    end
    
    it 'iterates over the vertecies' do
      root << (child_a << child_c) << child_b
      enum = root.each
      
      assert_equal root, enum.next
      assert_equal child_a, enum.next
      assert_equal child_c, enum.next
      assert_equal child_b, enum.next
      assert_raises(StopIteration) { enum.next }
    end
  end
  
  describe '#leafs' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, root.leafs
    end
    
    it 'iterates over the vertex itself for a leaf' do
      enum = root.leafs
      assert_equal root, enum.next
      assert_raises(StopIteration) { enum.next }
    end
    
    it 'iterates over the leafs of the tree left to right' do
      root << (child_a << child_c) << child_b
      enum = root.leafs
      
      assert_equal child_c, enum.next
      assert_equal child_b, enum.next
      assert_raises(StopIteration) { enum.next }
    end
    
    it 'iterates over the leafs of the tree right to left' do
      root << (child_a << child_c) << child_b
      enum = root.leafs rtl: true
      
      assert_equal child_b, enum.next
      assert_equal child_c, enum.next
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