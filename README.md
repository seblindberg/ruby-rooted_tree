# RootedTree

[![Gem Version](https://badge.fury.io/rb/rooted_tree.png)](http://badge.fury.io/rb/rooted_tree)
[![Build Status](https://travis-ci.org/seblindberg/ruby-rooted_tree.svg?branch=master)](https://travis-ci.org/seblindberg/ruby-rooted_tree)
[![Coverage Status](https://coveralls.io/repos/github/seblindberg/ruby-rooted_tree/badge.svg?branch=master)](https://coveralls.io/github/seblindberg/ruby-rooted_tree?branch=master)
[![Inline docs](http://inch-ci.org/github/seblindberg/ruby-rooted_tree.svg?branch=master)](http://inch-ci.org/github/seblindberg/ruby-rooted_tree)

A tree is a connected graph with no cycles. There, that is plenty of explanation. Please refer to https://en.wikipedia.org/wiki/Tree_structure for a more in depth description, but if you need one this library probably is not for you.

This gem technically implements a _rooted, ordered tree_, but that name is a mouthful. It is ment to be used as a building block when working with any tree shaped data. For a brief recap of the terminology please see below.

           A     A is the root.
      ┌────┼──┐  B, C and D are all children of A.
      B    C  D  E is a descendant of A.
    ┌─┼─┐ ┌┴┐ │  A is of degree 3 while C is of degree 2.
    E F G H I J  F is a leaf.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rooted_tree'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rooted_tree

## Usage

Please see the documentation for the complete API.

```ruby
# Create some nodes
root = RootedTree::Node.new
child_a = RootedTree::Node.new
child_b = RootedTree::Node.new

# Put the two children below the root
root << child_a << child_b

# Look at the result
p root # => RootedTree::Node:0x3fd5d54efda0
       #    ├─╴RootedTree::Node:0x3fd5d54c3ea8
       #    └─╴RootedTree::Node:0x3fd5d54ba894
```

The gem is primarily ment to be extended by other classes. The following example builds a tree of the files in the file system and displays it much like the command line tool `tree`.

```ruby
class FileSystemItem < RootedTree::Node
  def display
    inspect { |item| item.value }
  end

  def self.map_to_path path = '.', root: new(path)
    # Iterate over all of the files in the directory
    Dir[path + '/*'].each do |entry|
      # Create a new FileSystemItem for the entry
      item = new File.basename(entry)
      root << item
      # Continue to map the files and directories under
      # entry, if it is a directory
      map_to_path entry, root: item unless File.file? entry
    end

    root
  end
end

puts FileSystemItem.map_to_path('.').display
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rooted_tree.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

