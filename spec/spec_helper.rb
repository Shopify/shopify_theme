require 'minitest/autorun'
require 'minitest/pride'

MOCK_RESPONSES_DIR = "#{File.dirname(__FILE__)}/responses/"
ENV['test'] = '1'

module MockResponses
  def response(name)
    File.new(MOCK_RESPONSES_DIR + name)
  end
end