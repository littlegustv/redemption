#
# A model to generate an Affect with.
#
class AffectModel < Model

    # @return [Class] The Class of the affect, eg. AffectBless
    attr_reader :affect_class

    # @return [Hash, nil] Extra data overwrite on the affect, or nil
    attr_reader :data

    def initialize(row)
        super(row)
        @affect_class = Game.instance.affect_class_with_id(row[:affect_id])
        if row[:data]
            @data = JSON.parse(row[:data], symbolize_names: true)
        else
            @data = nil
        end
    end

end
