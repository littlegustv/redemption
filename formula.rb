class Formula

    def initialize(definition)
        @definition = definition.gsub(/\s+/, "")
    end

    def formula_for_player(player)
        player_formula = @definition
        player_formula.gsub!("level", player.level.to_s)
        return player_formula
    end

    def evaluate(player)
        return calculate(formula_for_player(player)).to_i
    end

    def calculate(substr)
        last_substr = ""
        number = 0
        loop do
            last_substr = substr
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
