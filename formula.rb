#
# A Formula object takes a string and turns it into an equation that can be evaluated for
# a given Mobile. The string will evaluate with floating point precision, but will round
# to an integer for the final result.
#
# String examples:
#
#   "[level] + 1d100 - [strength]" # single mobile
#   "([level] + 3) * 10"
#   "[0intelligence] + 1d[0strength] + [1wisdom]" # multi-mobile formula
#
class Formula

    #
    # Formula initializer. 
    #
    # @param [String] definition The formula represented by a string.
    #   "[0level] * 5 - [0wisdom]"
    #
    def initialize(definition)
        @definition = definition.gsub(/\s+/, "").downcase
    end

    #
    # Returns the unevaluated string for a given mobile, replacing stats and level
    # with actual values for the mobile.
    #
    #   "[level]+[wisdom]"
    #   # becomes
    #   "51+25"
    #
    # @param [Array<Mobile>, Mobile] mobiles A Mobile or Array of Mobiles to use in the formula.
    #
    # @return [String] The formula with all stats subbed with their values.
    #
    def formula_for_mobile(mobiles)
        mobiles = [mobiles].flatten
        mobile_formula = @definition.dup

        # multiple player format:
        # players = [actor, target]
        # formula = "[0level] + 1d100 - [1constitution]"
        #
        # single player format:
        # players = [actor]
        # formula = "[level] + 1d[strength]"

        mobile_formula.scan(/(\[(\d*)(\w*)\])/).each do |match, index_match, attribute|
            index = index_match.to_i
            if index >= mobiles.size
                log("Error in formula #{@definition} with mobiles [#{mobiles.map(&:name).join(", ")}]")
            end 
            symbol = attribute.to_sym
            case symbol
            when :level
                player_formula.sub!(match, mobiles[index].level.to_s)
            else
                player_formula.sub!(match, mobiles[index].stat(symbol).to_s)
            end 
        end

        return player_formula
    end

    #
    # Evaluate the formula for a mobile or array of mobiles and return
    # the result as an integer.
    #
    # @param [Mobile, Array<Mobile>] mobiles A mobile or an array of mobiles.
    #
    # @return [Integer] The result of the formula.
    #
    def evaluate(mobiles)
        return calculate(formula_for_player(players)).to_i
    end

    #
    # `calculate` is the recursive method that does the formula substitutions until all operations have been resolved.
    # Returns the resolved string as (ideally) a single number in the string.
    #
    # @param [String] substr The string or substring that is currently being resolved.
    #
    # @return [String] The result.
    #
    def calculate(substr)
        last_substr = ""
        number = 0
        loop do
            last_substr = substr.dup
            substr.scan(/(\(([^()]*)\))/).each do |bracket, content|
                substr.sub!(bracket, calculate(content))
            end
            substr.scan(/((-?\d+\.?\d*)d(-?\d+\.?\d*))/).each do |dice_str, count, sides|
                substr.sub!(dice_str, dice(count.to_f, sides.to_f).to_s)
            end
            substr.scan(/((-?\d+\.?\d*)\*(-?\d+\.?\d*))/).each do |multiplication, a, b|
                p a
                p b
                substr.sub!(multiplication, (a.to_f * b.to_f).to_s)
            end
            substr.scan(/((-?\d+\.?\d*)\/(-?\d+\.?\d*))/).each do |division, dividend, divisor|
                substr.sub!(division, (dividend.to_f / divisor.to_f).to_s)
            end
            substr.scan(/((-?\d+\.?\d*)\+(-?\d+\.?\d*))/).each do |addition, a, b|
                substr.sub!(addition, (a.to_f + b.to_f).to_s)
            end
            substr.scan(/((-?\d+\.?\d*)-(-?\d+\.?\d*))/).each do |subtraction, a, b|
                substr.sub!(subtraction, (a.to_f - b.to_f).to_s)
            end
            break if last_substr == substr
        end
        return substr
    end

end