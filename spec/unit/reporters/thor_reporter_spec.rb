require 'spec_helper'
require 'shopify_theme/reporters/thor_reporter'
require 'thor/shell/color'

module ShopifyTheme
  module Reporters
    describe "ThorReporter" do
      attr_reader :reporter
      before do
        @reporter = ThorReporter.new(Thor::Shell::Color.new)
      end

      it "should be able to log errors to stdout" do
        result = capture(:stdout) { reporter.error("danger will robinson") }
        assert_equal "danger will robinson\n", result
      end

      it "should be able to log warnings to stdout" do
        result = capture(:stdout) { reporter.warn("beware of dog") }
        assert_equal "beware of dog\n", result
      end

      it "should be able to log notices to stdout" do
        result = capture(:stdout) { reporter.notice("Ohai")}
        assert_equal "Ohai\n", result
      end

      it "should be able to log debug to stdout" do
        result = capture(:stdout) { reporter.debug("testing some things")}
        assert_equal "testing some things\n", result
      end

      # Shamelessly jacked from the Thor spec helper
      def capture(stream)
        begin
          stream = stream.to_s
          eval "$#{stream} = StringIO.new"
          yield
          result = eval("$#{stream}").string
        ensure
          eval("$#{stream} = #{stream.upcase}")
        end

        result
      end
    end
  end
end