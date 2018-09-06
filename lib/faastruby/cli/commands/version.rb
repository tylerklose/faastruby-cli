module FaaStRuby
  module Command
    class Version < BaseCommand
      def initialize(args)
        @args = args
      end

      def run
        puts FaaStRuby::VERSION
      end
    end
  end
end