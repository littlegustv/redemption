#

class Stat
    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :max_stat
    attr_reader :base_cap
    attr_reader :hard_cap

    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @max_stat = nil
        @base_cap = row[:base_cap]
        @hard_cap = row[:hard_cap]
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_stat
        self
    end

    def set_max_stat(max_stat)
        @max_stat = max_stat
    end

end
