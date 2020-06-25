#
# This query object is how a command argument is converted into a set of keywords with
# an offset and a quantity. This object can be passed into a call to `target` to find target(s).
#
class Query

    # @return [Integer] The offset value. (How many targets should be passed over before selecting results.)
    attr_reader :offset
    
    # @return [Integer, String] The quantity of desired results. If "all", then all valid results will be selected.
    attr_reader :quantity
    
    # @return [Set<Symbol>] The set of keywords as symbols.
    attr_reader :keywords

    def initialize(string, default_quantity = 1)
        if string == "all"
            @offset = 0
            @quantity = "all"
            @keywords = Set.new
            return
        else
            @offset = string[/(\d+|all)\./, 1] || 0
            @quantity = string[/(\d+|all)\*/, 1] || default_quantity
            @keywords = string[/((\d+|all).)?'?([a-zA-Z\s]+)'?/, 3].to_s.downcase.split.map(&:to_sym).to_set
        end
    end


    def to_query
        self        
    end

end