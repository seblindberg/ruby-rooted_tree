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
end