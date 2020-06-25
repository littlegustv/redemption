#
# The base (ideally abstract) Affect class.
#
class Affect

    # @return [GameObject, Mobile, Item] The target of the affect.
    attr_reader :target

    # @return [GameObject, nil] The source of the affect.
    attr_reader :source

    # @return [Boolean] Whether or not the affect is permanent.
    attr_accessor :permanent

    # @return [Boolean] Whether or not the affect is can be saved to the database.
    attr_accessor :savable

    # @return [Symbol] The visibility of the affect expressed as a Symbol:
    attr_accessor :visibility

    # @return [Float, nil] The time that the affect was applied, or `nil` if it is permanent.
    attr_reader :start_time

    # @return [Float, nil] The time that the affect will be cleared, or `nil` if it is permanent.
    attr_reader :clear_time

    # @return [Hash{Symbol => Integer, Float, Boolean, String}] Additional data used by the affect.
    #   Defined by Affect Subclasses.
    attr_reader :data

    # @return [Integer] The level of the affect.
    attr_reader :level

    # @return [Hash{Stat => Integer}, nil] Stat modifiers for the affect, or `nil` if it has none.
    attr_reader :modifiers

    # @return [Float, nil] The period of the Affect's `#periodic`, or `nil` if it has none.
    attr_reader :period

    # @return [Float, nil] The time when #periodic is next scheduled to be called, or `nil` if there is no such call.
    attr_reader :next_periodic_time

    #
    # Initialize a new Affect.
    # All subclasses should call this using `super` in their #initialize.
    #
    def initialize(
        target,
        source,
        level,
        duration,
        modifiers,
        period,
        permanent,
        visibility,
        savable
    )
        # initialize from arguments
        @target = target                        # The GameObjects that this affect is attached to.
        @source = source                        # GameObject that is the source of this affect - prefer nil when possible.
        @level = level
        @duration = duration
        overwrite_modifiers(modifiers)
        @period = period
        @next_periodic_time = nil
        @permanent = permanent
        @visibility = visibility
        @savable = savable

        # initialize other stuff!
        if @period
            @period = @period.to_f
        end
        if @duration
            @duration = @duration.to_f
        end
        @start_time = 0                           # Time of the affect's application.
        @clear_time = nil                         # Time when the affect should clear, or nil if permanent.
        @data = self.class.affect_info.dig(:data) # Additional data. Only "primitives". Saved to the database.
        @events = nil                             # keeps track of events
        @active = false
    end

    #
    # Apply the Affect to its target GameObject according to the Affect's application type.
    #
    # @param [Boolean] silent If true, application will not trigger start or refresh messages (default = `false`).
    #
    # @return [self, nil] Returns `self` if application was successful, otherwise `nil`.
    #
    def apply(silent = false)
        if !@target || !@target.active
            # no target or target is inactive, don't apply
            return false
        end  

        # find existing affects based on existing_affect_selection rules
        # @type [Symbol] # :none, :affect_id, :affect_id_with_source, :keywords, or :keywords_and_source
        existing_affect_selection = self.class.affect_info[:existing_affect_selection]
        existing_affects = nil
        case existing_affect_selection
        when :none
            existing_affects = []
        when :affect_id
            existing_affects = @target.affects.select { |a| a.id == self.id }
        when :affect_id_with_source
            existing_affects = @target.affects.select { |a| a.id == self.id && a.source == @source }
        when :keywords
            existing_affects = @target.affects.select { |a| keywords.shares_keywords?(a.keywords) }
        when :keywords_and_source
            existing_affects = @target.affects.select { |a| keywords.shares_keywords?(a.keywords) && a.source == @source }
        else
            log "Unknown existing affect selection type in Affect#apply, affect: #{self.name} target #{@target.name}"
            existing_affects = []
        end

        # @type [Symbol] :overwrite, :stack, :single, or :multiple
        application_type = self.class.affect_info[:application_type]
        if !existing_affects.empty?
            case application_type
            when :overwrite
                # delete old affect(s) and push the new one
                existing_affects.each { |a| a.clear(true) }
                self.send_refresh_messages if !silent
                self.start
            when :stack
                existing_affects.first.send_refresh_messages if !silent
                existing_affects.first.stack(self)
                return nil
            when :single
                # existing single affect already exists!
                return nil
            when :multiple
                # :multiple application type affects stack no matter what
                self.send_start_messages if !silent
                self.start
            else
                log "Unknown application type #{application_type} in Affect#apply, affect: #{self.name} target: #{@target.name}"
                return nil
            end
        else
            # no relevant existing affects, apply normally
            self.send_start_messages if !silent
            self.start
        end
        @active = true
        @target.add_affect(self)
        set_source(@source)
        @start_time = Game.instance.frame_time
        set_duration(@duration)
        if @period
            @next_periodic_time = @start_time + @period
            Game.instance.add_periodic_affect(self)
        end
        if @target.is_a?(Mobile)
            @target.try_add_to_regen_mobs
        end
        return self
    end

    #
    # Clear the affect. Remove from target's affects and source's source_affects as necessary.
    #
    # @param [Boolean] silent If true, send_complete_message won't be called.
    #
    # @return [nil]
    #
    def clear(silent = false)
        complete
        remove_events
        @target.remove_affect(self)
        if @source 
            @source.remove_source_affect(self)
        end
        toggle_periodic(nil)
        Game.instance.remove_affect(self)
        send_complete_messages if !silent
        return
    end

    #
    # Query the Affect's visibility.
    #
    # @return [Boolean] `true` if the affect visibility is `:hidden`, `false` otherwise.
    #
    def hidden?
        return @visibility == :hidden
    end

    #
    # Set the source of the Affect.
    #
    # @param [GameObject] source The new source of the Affect.
    #
    # @return [GameObject] The new source.
    #
    def set_source(source)
        # Remove from old source, if necessary
        if @source
            @source.remove_source_affect(self)
        end
        @source = source
        # Add to new source's source_affect array
        if @source
            @source.add_source_affect(self)
        end
        return @source
    end

    #
    # Sets the Affect's period to `new_period`. Clears any scheduled calls to `#periodic`
    # and schedules a new one unless the new period is nil.
    #
    # Examples:  
    #   `affect.toggle_periodic(3.5) # => Begins calls with a period of 3.5`  
    #   `affect.toggle_periodic(nil) # => Cancels further #periodic calls`  
    #
    # @param [Float, nil] new_period The new period of the affect as a Float, or nil to
    #   disable `#periodic` calls.
    #
    # @return [Boolean] true if a new call was scheduled, otherwise `false` (via `#schedule_next_periodic_time`).
    #
    def toggle_periodic(new_period)
        if @period
            Game.instance.remove_periodic_affect(self)
        end
        @period = new_period
        return schedule_next_periodic_time
    end

    #
    # Schedules a call to the Affect's `#periodic` by the Game instance, unless the Affect's period is nil.
    #
    # @return [Boolean] `true` if a call was scheduled, otherwise `false`.
    #
    def schedule_next_periodic_time
        if @period
            if @next_periodic_time
                @next_periodic_time += @period
            else
                @next_periodic_time = Game.instance.frame_time + @period
            end
            Game.instance.add_periodic_affect(self)
            return true
        else
            @next_periodic_time = nil
            return false
        end
    end

    #
    # Query the Affect's `modifiers` hash for the value for a Stat, defaulting to 0.
    #
    # @param [Stat, Symbol] stat The Stat (or symbol for a Stat) to retrieve the value for.
    #
    # @return [Integer] The value for the Stat, or 0 if it doesn't exist.
    #
    def modifier( stat )
        stat = stat.to_stat
        if @modifiers
            return @modifiers.dig(stat) || 0
        else
            return 0
        end
    end

    #
    # Construct a string to display in a list of affects.
    #
    # @return [String] The string to display.
    #
    def summary
        if @modifiers && @modifiers.length > 0
            return "Spell: #{name.rpad(17)} : #{ @modifiers.map{ |stat, value| "modifies #{stat.name} by #{value}#{stat.percent?} #{ duration_string }" }.join("\n" + (" " * 24) + " : ") }"
        else
            if @permanent
                return "Spell: #{name}"
            else
                return "Spell: #{name.rpad(17)} : modifies none by 0 #{ duration_string }"
            end
        end
    end

    #
    # Construct a duration string based on the remaining time on the affect.
    #
    # @return [String] The Affect's duration as a string.
    #
    def duration_string
        if @permanent
            return "permanently"
        else
            return "for #{duration.to_i} seconds"
        end
    end

    #
    # Combine modifiers from a new affect and renew duration of this affect to
    # the longer duration of the two.
    #
    # @param [Affect] new_affect The affect to combine the modifiers of.
    #
    # @return [void]
    #
    def stack(new_affect)
        if new_affect.modifiers
            @modifiers = @modifiers || Hash.new
            new_affect.modifiers.each do |stat, bonus|
                @modifiers[stat] = bonus + (@modifiers[stat] || 0)
            end
        end
        set_duration([duration.to_f, new_affect.duration.to_f].max)
    end

    #
    # Overwrite the modifiers with a new Hash of modifiers.
    # (Probably only used when loading existing affects from database.)
    #
    # @param [Hash{Stat => Integer}] modifiers The new modifier Hash.
    #
    # @return [void]
    #
    def overwrite_modifiers(modifiers)
        if modifiers
            @modifiers = modifiers.map{|stat, value| [stat.to_stat, value] }.to_h
        else 
            @modifiers = nil
        end
    end

    #
    # Overwrite the Data hash with a new hash
    # (Probably only used when loading existing affects from the database.)
    #
    # @param [Hash{Symbol => Integer, Float, Boolean, String}] data Additional data to be used by the affect.
    #
    # @return [Hash{Symbol => Integer, Float, Boolean, String}] The new data hash.
    #
    def overwrite_data(data)
        @data = data
    end

    #
    # Derive the remaining duration of the Affect by subtracting the current frame_time from clear_time.
    #
    # @return [Float, nil] The remaining duration of the affect or nil if there is no clear time.
    #
    def duration
        if @clear_time
            return @clear_time - Game.instance.frame_time
        end
    end

    #
    # Sets the duration of the affect. If new duration is `nil`, Affect is set to be permanent.
    #
    # @param [Float, nil] duration The new duration.
    #
    # @return [void]
    #
    def set_duration(duration)
        if @clear_time && @active
            Game.instance.remove_timed_affect(self)
        end
        @duration = duration
        if @duration && !@permanent
            @clear_time = Game.instance.frame_time + duration
            if @active
                Game.instance.add_timed_affect(self)
            end
        else
            @permanent = true
        end
    end

    #
    # The ID of the Affect.
    #
    # @return [Integer] The Affect Class's ID, or -1 if it hasn't been set.
    #
    def id
        self.class.id || -1
    end

    #
    # The name of the Affect.
    #
    # @return [String] The Affect's name.
    #
    def name
        return self.class.affect_info[:name]
    end

    #
    # Returns true if the Affect's keywords contains a match for a given query.
    #
    # @see Keywords#fuzzy_match
    #
    # @param [String, Array<String>, Set<Symbol>, Query] query The query.
    #
    # @return [Boolean] True if the affect's keywords fully match the query.
    #
    def fuzzy_match(query)
        if keywords
            return keywords.fuzzy_match(query)
        end
        return false
    end

    #
    # The keywords of the affect, 
    #
    # @return [Keywords] The Keywords.
    #
    def keywords
        return self.class.keywords
    end

    #
    # Gets the Keywords for the Affect Class.
    #
    # @return [Keywords] The Keywords.
    #
    def self.keywords
        return @keywords || @keywords = Keywords.keywords_for_array(affect_info[:keywords])
    end

    #
    # Check for common keywords between the Affect and another Affect.
    #
    # @param [Affect] affect The other Affect.
    #
    # @return [Boolean] True if there are common keywords, otherwise false.
    #
    def shares_keywords_with?(affect)
        return self.keywords.intersect?(keywords)
    end

    #
    # Override this method to perform actions and logic.
    # This is also where you add event listeners.  
    # Always gets called when an affect is applied.
    #
    # @return [void]
    #
    def start
    end

    #
    # Override this method to perform actions and logic.  
    # Always gets called when an affect is cleared.
    #
    # @return [void]
    #
    def complete
    end

    #
    # Override this method to output start messages.  
    # Doesn't always get called!
    #
    # @return [void]
    #
    def send_start_messages
    end

    #
    # Override this method to output refresh messages.  
    # Doesn't always get called!
    #
    # @return [void]
    #
    def send_refresh_messages
        @target.output "Your #{name} has been refreshed!"
    end

    #
    # Override this method to output completion messages.  
    # Doesn't always get called!
    #
    # @return [void]
    #
    def send_complete_messages
    end

    #
    # Periodic method to override in subclasses.
    #
    # @return [void]
    #
    def periodic
    end

    #
    # Adds an event listener to the affect. Also adds it to the Game instance.
    #
    # @param [GameObject] object The GameObject that responds to the event.
    # @param [Symbol] event The event.
    # @param [Symbol] callback The method of the affect that will be called when the object responds to the event.
    #
    # @return [nil]
    #
    def add_event_listener(object, event, callback)
        Game.instance.add_event_listener(object, event, self, callback)
        if !@events
            @events = []
        end
        @events << [object, event]
        return
    end

    #
    # Clear an event listener from the affect. Also removes it from the Game instance.
    #
    # @param [GameObject] object The GameObject that responds to the event.
    # @param [Symbol] event The event.
    #
    # @return [nil]
    #
    def remove_event_listener(object, event)
        Game.instance.remove_event_listener(object, event, self)
        @events.delete [object, event]
        if @events.size == 0
            @events = nil
        end
        return 
    end

    #
    # Remove all events from the affect. Also removes them from the Game instance.
    #
    # @return [nil]
    #
    def remove_events
        if @events
            @events.each do |object, event|
                Game.instance.remove_event_listener(object, event, self)
            end
            @events = nil
        end
        return 
    end

    #
    # A hash of base values to override in subclasses.
    #
    # @return [Hash] The basic affect_info values.
    #
    def self.affect_info
        return @info || @info = {
            name: "affect name",
            keywords: "affect_keywords",
            existing_affect_selection: :affect_id, # :none, :affect_id, :affect_id_with_source, :keywords, or :keywords_and_source
            application_type: :overwrite,    # :overwrite, :stack, :single, :multiple
            data: @data
        }
    end

    #
    # Set the ID of this Affect Class.
    #
    # @param [Integer] id The new ID of this Affect Class.
    #
    # @return [Integer] The new ID.
    #
    def self.set_id(id)
        @id = id
    end

    #
    # Get the ID of the Affect Class.
    #
    # @return [Integer] The ID.
    #
    def self.id
        @id
    end

    #
    # Set the Data of the Affect Class.
    #
    # @param [<Type>] data <description>
    #
    # @return [<Type>] <description>
    #
    def self.set_data(data)        
        @data = data
    end
    
end
