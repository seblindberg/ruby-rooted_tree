# frozen_string_literal: true

require 'test_helper'

class Treelike
  include RootedTree::Tree
  attr_reader :root

  def initialize
    @root = RootedTree::Node.new(:a)
    @root << RootedTree::Node.new(:b)
    @root << RootedTree::Node.new(:c)
  end
end

describe RootedTree::Tree do
  subject { Treelike.new }

  describe '#freeze' do
    it 'freezes the node structure' do
      subject.freeze
      assert subject.root.frozen?
    end
  end

  describe '#degree' do
    it 'returns the maximum degree' do
      assert_equal subject.root.max_degree, subject.degree
    end
  end

  describe '#depth' do
    it 'returns the maximum node depth in the tree' do
      assert_equal subject.root.max_depth, subject.depth
    end
  end

  describe '#each_node' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, subject.each_node
    end

    it 'iterates over all of the nodes' do
      assert_equal subject.root.each.to_a, subject.each_node.to_a
    end

    it 'accepts a block' do
      nodes = subject.root.each
      subject.each_node { |node| assert_equal nodes.next, node }
    end
  end

  describe '#each_leaf' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, subject.each_leaf
    end

    it 'iterates over all of the nodes' do
      assert_equal subject.root.leafs.to_a, subject.each_leaf.to_a
    end

    it 'accepts a block' do
      leafs = subject.root.leafs
      subject.each_leaf { |leaf| assert_equal leafs.next, leaf }
    end
  end

  describe '#each_edge' do
    it 'returns an enumerator' do
      assert_kind_of Enumerator, subject.each_edge
    end

    it 'iterates over all of the nodes' do
      assert_equal subject.root.edges.to_a, subject.each_edge.to_a
    end

    it 'accepts a block' do
      edges = subject.root.edges
      subject.each_edge { |*edge| assert_equal edges.next, edge }
    end
  end
end
