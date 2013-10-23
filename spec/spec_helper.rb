require 'minitest/autorun'
require 'minitest/pride'

MOCK_RESPONSES_DIR = "#{File.dirname(__FILE__)}/responses/"

module MockResponses
  def response(name)
    File.new(MOCK_RESPONSES_DIR + name)
  end
end