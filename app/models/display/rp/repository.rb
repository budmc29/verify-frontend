require 'ostruct'

module Display
  module Rp
    class Repository
      def initialize(translator)
        @translator = translator
      end

      def fetch(simple_id)
        other_ways_text = @translator.translate("rps.#{simple_id}.other_ways_text")
        other_ways_description = @translator.translate("rps.#{simple_id}.other_ways_description")
        name = @translator.translate("rps.#{simple_id}.name")
        OpenStruct.new(other_ways_text: other_ways_text, other_ways_description: other_ways_description, name: name)
      end
    end
  end
end
