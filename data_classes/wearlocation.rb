class WearLocation

    attr_reader :id
    attr_reader :display_string

    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @display_string = row[:display_string]
    end

end
