class Affect

    attr_reader :name, :priority, :application_type, :source, :modifiers, :duration

    def initialize(
        source:,
        target:,
        keywords:,
        name:,
        level:,
        duration: 0,
        modifiers: {},
        period: nil,
        priority: 100,
        application_type: :global_overwrite,
        permanent: false
    )
        @source = source
        @target = target
        @keywords = keywords
        @name = name
        @level = level
        @duration = duration
        @modifiers = modifiers
        @priority = priority
        @period = period
        @application_type = application_type   # :global_overwrite, :global_stack, :global_single,
                                               # :source_overwrite, :source_stack, :source_single
        @permanent = permanent
        @clock = 0
    end

    # override this method to add event listeners - Make sure you remove them in +unhook+!
    def hook
    end

    # override this method to clear event listeners
    def unhook
    end

    def start
        # @target.output "Affect has started: #{@duration} seconds remain."
    end

    def refresh
        @target.output "Your #{@name} is refreshed!"
    end

    def update( elapsed )
        if !@permanent
            @duration -= elapsed
            if @period
                @clock += elapsed
                if @clock >= @period
                    periodic
                    @clock = 0
                end
            end
            if @duration <= 0
                unhook
                @target.affects.delete self
                complete
            end
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

    # Combine modifiers from a new affect and renew duration of this affect to
    # the longer duration of the two
    def stack(new_affect)
        new_affect.modifiers.each do |stat, bonus|
            @modifiers[stat] = bonus + (@modifiers[stat] || 0)
        end
        @duration = [@duration.to_i, new_affect.duration.to_i].max
    end

    # Check to see if this affect shares any common ancestors with another, ignoring superclasses
    # above and including Affect
    def shares_ancestors_with?(affect)
        intersection = affect.class.ancestors & self.class.ancestors      # get the intersection of ancestors of the two classes
        return !intersection.slice(0, intersection.index(Affect)).empty?  # slice the array elements preceding Affect: these will be common ancestors
    end                                                                   # if this array is empty after the slice, then there are no common ancestors

end
