class Affect
    attr_accessor :duration
    attr_accessor :permanent
    attr_accessor :source
    attr_accessor :savable
    attr_reader :application_type
    attr_reader :hidden
    attr_reader :level
    attr_reader :modifiers
    attr_reader :name
    attr_reader :priority

    def initialize(
        game:,
        source:,
        target:,
        keywords:,
        name:,
        level: 0,
        duration: 0,
        modifiers: {},
        period: nil,
        priority: 100,
        application_type: :global_overwrite,
        permanent: false,
        hidden: false
    )
        @game = game
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
        @hidden = hidden
        @savable = true

        @clock = 0
        @conditions = []
    end

    # Override this method to output start messages.
    # Doesn't always get called!
    def send_start_messages
    end

    # Override this method to output refresh messages.
    # Doesn't always get called!
    def send_refresh_messages
        @target.output "Your #{@name} is refreshed!"
    end

    # Override this method to output ending messages.
    # Doesn't always get called!
    def send_complete_messages
    end

    # Override this method to perform actions and logic.
    # This is also where you add event listeners. Make sure you remove them in +complete+.
    #
    # Always gets called when an affect is applied. +start+ can be called multiple times
    # if the affect application type is :global_stack or :source_stack.
    def start
    end

    # Override this method to perform actions and logic.
    # This is where you remove event listeners.
    #
    # Always gets called when an affect is cleared.
    def complete
    end

    def update( elapsed )
        if @period
            @clock += elapsed
            if @clock >= @period
                periodic
                @clock = 0
            end
        end
        @duration -= elapsed if !@permanent
        if (@duration.to_i <= 0 && !@permanent) || (@conditions.length > 0 && @conditions.map { |condition| condition.evaluate }.include?(false))
            clear(silent: false)
        end
    end

    # Call this method to remove an affect from a GameObject.
    def clear(silent: false)
        send_complete_messages if !silent
        complete
        @target.affects.delete self
        @game.remove_affect(self)
    end

    def periodic
    end

    def check( key )
        @keywords.include?( key )
    end

    def modifier( key )
        return @modifiers[ key ].to_i
    end

    def summary
        if @modifiers.length > 0
            return "Spell: #{@name.ljust(17)} : #{ @modifiers.map{ |key, value| "modifies #{key} by #{value} #{ duration_string }" }.join("\n" + (" " * 24) + " : ") }"
        else
            return "Spell: #{@name}"
        end
    end

    def duration_string
        if @permanent
            return "permanently"
        else
            return "for #{@duration.to_i} seconds"
        end
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

    def overwrite_modifiers(modifiers)
        @modifiers = modifiers
    end

end

# The AffectCondition is an object that an +Affect+ can evaluate at each +update+ to determine whether or not     <br>
# the +Affect+ should clear itself. When added to an +Affect+'s +conditions+ array, the affect will clear itself  <br>
# upon finding any condition to be false.
#                                                                               # evaluates as:
#     AffectCondition.new(some_mobile, [:room], :==, some_room, [])             # some_mobile.room == some_room
#     AffectCondition.new(some_mobile, [:room, :area], :==, some_room, [:area]) # some_mobile.room.area == some_room.area
#
class AffectCondition

    # Creates a new instance.
    # +l_object+:: Base object on the lefthand side of the operator
    # +l_symbols+:: Any methods to call on l_object at each +evaluate+
    # +operator+:: The comparison operator
    # +r_object+:: Base object on the righthand side of the operator
    # +r_symbols+:: Any methods to call on r_object at each +evaluate+
    def initialize(l_object, l_symbols, operator, r_object, r_symbols)
        @l_object = (l_object.frozen?) ? l_object : WeakRef.new(l_object)
        @l_symbols = l_symbols
        @operator = operator
        @r_object = (r_object.frozen?) ? r_object : WeakRef.new(r_object)
        @r_symbols = r_symbols
    end

    # The affect will call this in +update+
    def evaluate
        if (!@l_object.frozen? && !@l_object.weakref_alive?) || (!@r_object.frozen? && !@r_object.weakref_alive?)
            return false
        end
        l = @l_object
        @l_symbols.each { |symbol| l = l.send(symbol) }
        r = @r_object
        @r_symbols.each { |symbol| r = r.send(symbol) }
        return l.send(@operator, r)
    end

end
