class WearLocation

    attr_reader :id
    attr_reader :display_string

    def initialize(row)
        @id = row[:id]
        @display_string = row[:display_string]
    end

end
