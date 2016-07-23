describe RootedTree::Tree do
  subject { RootedTree::Tree }
  
  let(:node_class) { RootedTree::Node }
  let(:root_node) { node_class.new }
  let(:child_node) { node_class.new }
  let(:tree) { root_node.append_child(child_node).tree }
  
  describe '.new' do
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
    
    it 'freezes the node structure' do
      root_node << child_node
      subject.new root_node
      assert root_node.frozen?
      assert child_node.frozen?
    end
  end
  
  describe '#degree' do
    it 'returns 0 for single nodes' do
      tree = subject.new root_node
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