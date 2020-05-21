class Formula

    def initialize(definition)
        @definition = definition.gsub(/\s+/, "").downcase
    end

    def formula_for_player(players)
        players = [players].flatten
        player_formula = @definition.dup

        # multiple player format:
        # players = [actor, target]
        # formula = "[0level] + 1d100 - [1constitution]"
        player_formula.scan(/(\[(\d*)(\w*)\])/).each do |match, index_match, attribute|
            index = index_match.to_i
            symbol = attribute.to_sym
            case symbol
            when :level
                player_formula.sub!(match, players[index].level.to_s)
            else
                player_formula.sub!(match, players[index].stat(symbol).to_s)
            end
        end
        # single player format:
        # players = [actor]
        # formula = "[level] + 1d[strength]"
        player_formula.scan(/(\[(\w*)\])/).each do |match, attribute|
            symbol = attribute.to_sym
            case symbol
            when :level
                player_formula.sub!(match, players.first.level.to_s)
            else
                player_formula.sub!(match, players.first.stat(symbol).to_s)
            end
        end

        return player_formula
    end

    def evaluate(players)
        return calculate(formula_for_player(players)).to_i
    end

    def calculate(substr)
        last_substr = ""
        number = 0
        loop do
            last_substr = substr.dup
            substr.scan(/(\(([^()]*)\))/).each do |bracket, content|
                substr.sub!(bracket, calculate(content))
            end
            substr.scan(/((-?\d+)d(-?\d+))/).each do |dice_str, count, sides|
                substr.sub!(dice_str, dice(count.to_i, sides.to_i).to_s)
            end
            substr.scan(/((-?\d+)\*(-?\d+))/).each do |multiplication, a, b|
                substr.sub!(multiplication, (a.to_i * b.to_i).to_s)
            end
            substr.scan(/((-?\d+)\/(-?\d+))/).each do |division, dividend, divisor|
                substr.sub!(division, (dividend.to_i / divisor.to_i).to_i.to_s)
            end
            substr.scan(/((-?\d+)\+(-?\d+))/).each do |addition, a, b|
                substr.sub!(addition, (a.to_i + b.to_i).to_s)
            end
            substr.scan(/((-?\d+)-(-?\d+))/).each do |subtraction, a, b|
                substr.sub!(subtraction, (a.to_i - b.to_i).to_s)
            end
            break if last_substr == substr
        end
        return substr
    end

end
