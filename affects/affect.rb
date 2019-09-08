class Affect

    attr_accessor :name

    def initialize( target, keywords, duration, modifiers = {}, period = 60 )
        @target = target
        @keywords = keywords
        @period = period
        @name = @keywords.first
        @duration = duration
        @clock = 0
        @modifiers = modifiers
        start
    end

    def start
        # @target.output "Affect has started: #{@duration} seconds remain."
    end

    def update( elapsed )
        @duration -= elapsed
        @clock += elapsed
        if @clock >= @period
            periodic
            @clock = 0
        end
        if @duration <= 0
            @target.affects.delete self
            complete
        end
    end

    def periodic
    end

    def complete
        # @target.output "Affect has worn off."
    end

    def check( key )
        @keywords.include?( key )
    end

    def modifier( key )
        return @modifiers[ key ].to_i
    end

    def summary
%Q(Spell: #{@name.ljust(17)} : #{ @modifiers.map{ |key, value| "modifies #{key} by #{value} for #{ duration } hours" }.join("\n" + (" " * 24) + " : ") } )
    end

    def duration
        @duration.to_i
    end

end
