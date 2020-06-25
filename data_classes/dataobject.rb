# 
# Base DataObject class. Other data_class objects (Direction, Element, Noun, Stat, etc) inherit from this one.
#
class DataObject

    # @return [Integer] The ID of the Direction.
    attr_reader :id

    # @return [String] The name of the direction.  
    attr_reader :name

    # @return [Symbol] The symbol of the direction.
    attr_reader :symbol

    def initialize(id, name, symbol)
        # @type [Integer]
        @id = id.to_i
        # @type [String, nil]
        @name = nil
        if name
            @name = name.to_s
        end
        # @type [Symbol, nil]
        @symbol = nil
        if symbol
            @symbol = symbol.to_sym
        end
            
        if @name && @symbol.nil?
            # if name is set but not symbol, use name to derive symbol.
            @symbol = @name.gsub(/ /, "_").to_sym
        elsif @symbol && @name.nil?
            # if symbol is set but not name, use symbol to derive name.
            @name = @symbol.to_s.gsub(/_/, " ")
        end
    end

    #
    # Object equality. 
    #
    # @param [Object] other_object Another object to check for equality against.
    #
    # @return [Boolean] Returns true if this object or its non-nil symbol is equal to other_object.
    #
    def ==(other_object)
        if @symbol
            super(other_object) || @symbol == other_object
        else
            super(other_object)
        end
    end

end
