require 'test_helper'

class RootedTreeTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RootedTree::VERSION
  end
end
