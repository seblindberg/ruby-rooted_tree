# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
SimpleCov.start 'test_frameworks'

require 'rooted_tree'

require 'minitest/autorun'
