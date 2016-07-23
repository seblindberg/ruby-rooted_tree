describe RootedTree::Tree do
  subject { RootedTree::Tree }
  
  let(:node_class) { RootedTree::Node }
  let(:root_node) { node_class.new }
  let(:child_node) { node_class.new }
  let(:tree) { root_node.append_child(child_node).tree }
  
  describe '.new' do
    it 'accepts no arguments' do
      tree = subject.new
      assert_kind_of RootedTree::Node, tree.root
      assert tree.root.root?
      assert tree.root.leaf?
    end
    
    it 'accepts root nodes' do
      root_node << child_node
      tree = subject.new root_node
      assert_same root_node, tree.root
    end
    
    it 'accepts child nodes' do
      root_node << child_node
      tree = subject.new child_node
      assert_same root_node, tree.root
    end
  end
  
  describe '#degree' do
    it 'returns 0 for single nodes' do
      tree = subject.new
      assert_equal 0, tree.degree
    end
  
    it 'returns 1 for leafs' do
      assert_equal 1, tree.degree
    end
    
    it 'returns the maximum degree' do
      root_node << (node_class.new << node_class.new << node_class.new)
      assert_equal 2, tree.degree
    end
  end
end