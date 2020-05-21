class AffectModel < Model

    attr_reader :affect_class # class of the affect to apply, eg. AffectBless
    attr_reader :data # either a hash of data for the affect to overwrite with or nil

    def initialize(row)
        @affect_class = Game.instance.affect_class_with_id(row[:affect_id])
        if row[:data]
            @data = JSON.parse(row[:data], symbolize_names: true)
        else
            @data = nil
        end
    end

end
