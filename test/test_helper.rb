require 'test/unit'
require 'rubygems'
require 'mocha'
# # Load the environment
unless defined? RADIANT_ROOT
  ENV["RAILS_ENV"] = "test"
  require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/environment"
end
require "#{RADIANT_ROOT}/test/test_helper"

class ActiveSupport::TestCase
  
  # Include a helper to make testing Radius tags easier
  test_helper :extension_tags
  
  # Add the fixture directory to the fixture path
  self.fixture_path << File.dirname(__FILE__) + "/fixtures"
  self.fixture_path << File.expand_path(File.dirname(__FILE__) + '/../../../../test/fixtures')
  
  # Add more helper methods to be used by all extension tests here...
  
end
