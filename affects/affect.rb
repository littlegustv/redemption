class Affect
    attr_accessor :permanent
    attr_accessor :savable
    attr_accessor :visibility
    attr_reader :start_time
    attr_reader :clear_time
    attr_reader :data
    attr_reader :level
    attr_reader :modifiers
    attr_reader :period
    attr_reader :next_periodic_time
    attr_reader :target
    attr_reader :source

    module Visibility
        NORMAL = 0
        PASSIVE = 1
        HIDDEN = 2

        STRINGS = {
            NORMAL => "normal",
            PASSIVE => "passive",
            HIDDEN => "hidden",
        }
    end

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
        @target = target                        # The GameObjects that this affect is attached to.
        @source = source                        # GameObject that is the source of this affect - prefer nil when possible.
        @keywords = keywords
        @name = name
        @level = level
        @duration = duration.to_f
        overwrite_modifiers(modifiers)
        @period = period
        @next_periodic_time = nil
        @application_type = application_type   # :global_overwrite, :global_stack, :global_single, :global_unique_data,
                                               # :source_overwrite, :source_stack, :source_single, :source_unique_data,
                                               # :multiple
        @permanent = permanent
        @visibility = visibility
        @savable = true
        @info = nil

        if @period
            @period = @period.to_f
        end
        @start_time = 0                           # Time of the affect's application.
        @clear_time = nil                         # Time when the affect should clear, or nil if permanent.
        @clock = 0
        @data = self.class.affect_info.dig(:data) # Additional data. Only "primitives". Saved to the database.

        @events = nil                             # keeps track of events
        @active = false

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

    def hidden?
        @visibility == Visibility::HIDDEN
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

    def add_event_listener(object, event, callback)
        Game.instance.add_event_listener(object, event, self, callback)
        if !@events
            @events = []
        end
        @events << [object, event]
    end

    def remove_event_listener(object, event)
        Game.instance.remove_event_listener(object, event, self)
        if @events.size == 0
            @events = nil
        end
    end

    def remove_events
        if @events
            @events.each do |object, event|
                Game.instance.remove_event_listener(object, event, self)
            end
            @events = nil
        end
    end

    def update
        if @period
            periodic
            if @period
                schedule_next_periodic_time
            end
        end
    end

    ##
    # Apply this affect to a +GameObject+ according to its application type
    # +target+:: The GameObject that is the target of this affect
    # +silent+:: Whether or not the affect should send its application messages. Defaults to false. (boolean)
    # returns +self+ on successful application, or +nil+ if application of affect fails
    def apply(silent = false)
        # return false
        if !@target || !@target.active
            # no target or target is inactive, don't apply
            return false
        end

        existing_affects = nil
        if @target.affects
            existing_affects = @target.affects.select { |a| self.shares_keywords_with?(a) }
            if [:source_overwrite, :source_stack, :source_single, :source_unique_data].include?(@application_type) && @source
                existing_affects.select! { |a| a.source == @source }
            end
        end
        if existing_affects && !existing_affects.empty?
            case @application_type
            when :global_overwrite, :source_overwrite
                # delete old affect(s) and push the new one
                existing_affects.each { |a| a.clear(true) }
                self.send_refresh_messages if !silent
                self.start
            when :global_stack, :source_stack
                existing_affects.first.send_refresh_messages if !silent
                existing_affects.first.stack(self)
                return nil
            when :global_single, :source_single
                # existing single affect already exists!
                return nil
            when :global_unique_data, :source_unique_data
                if existing_affects.find { |a| a.data == self.data }.nil?
                    self.send_start_messages if !silent
                    self.start
                else
                    return nil
                end
            when :multiple
                # :multiple application type affects stack no matter what
                self.send_start_messages if !silent
                self.start
            else
                log "Unknown application type #{@application_type} in affect.apply, affect: #{self.name} target: #{@target.name}"
                return nil
            end
        else
            # no relevant existing affects, apply normally
            self.send_start_messages if !silent
            self.start
        end
        @active = true
        if @target.affects
            @target.affects.unshift(self)
        else
            @target.affects = [self]
        end
        if @source
            if @source.source_affects
                @source.source_affects << self
            else
                @source.source_affects = [self]
            end
        end
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

    def set_source(source)
        # log "transferring affect source #{self.name}"
        if @source
            @source.source_affects.delete(self)
        end
        @source = source
        if @source
            @source.source_affects << self
        end
    end

    # Call this method to remove an affect from a GameObject.
    def clear(silent = false)
        complete
        remove_events
        @target.affects.delete self
        if @target.affects.size == 0
            @target.affects = nil
        end
        if @source && @source.source_affects
            @source.source_affects.delete(self)
            if @source.source_affects.size == 0
                @source.source_affects = nil
            end
        end
        toggle_periodic(nil)
        Game.instance.destroy_affect(self)
        send_complete_messages if !silent
    end

    def toggle_periodic(new_period)
        if @period
            Game.instance.remove_periodic_affect(self)
        end
        @period = new_period
        self.schedule_next_periodic_time
    end

    def schedule_next_periodic_time
        if @period
            if @next_periodic_time
                @next_periodic_time += @period
            else
                @next_periodic_time = Game.instance.frame_time + @period
            end
            Game.instance.add_periodic_affect(self)
        else
            @next_periodic_time = nil
        end
    end

    def periodic

    end

    def check( key )
        @keywords.include?( key )
    end

    def modifier( stat )
        if @modifiers
            return @modifiers.dig(stat) || 0
        else
            return 0
        end
    end

    def summary
        if @modifiers && @modifiers.length > 0
            return "Spell: #{@name.rpad(17)} : #{ @modifiers.map{ |stat, value| "modifies #{stat.name} by #{value}#{stat.percent?} #{ duration_string }" }.join("\n" + (" " * 24) + " : ") }"
        else
            if @permanent
                return "Spell: #{@name}"
            else
                return "Spell: #{@name.rpad(17)} : modifies none by 0 #{ duration_string }"
            end
        end
    end

    def duration_string
        if @permanent
            return "permanently"
        else
            return "for #{duration.to_i} seconds"
        end
    end

    # Combine modifiers from a new affect and renew duration of this affect to
    # the longer duration of the two
    def stack(new_affect)
        if new_affect.modifiers
            @modifiers = @modifiers || Hash.new
            new_affect.modifiers.each do |stat, bonus|
                @modifiers[stat] = bonus + (@modifiers[stat] || 0)
            end
        end
        set_duration([duration.to_f, new_affect.duration.to_f].max)
    end

    # Check to see if this affect shares any common ancestors with another, ignoring superclasses
    # above and including Affect
    def shares_ancestors_with?(affect)
        intersection = affect.class.ancestors & self.class.ancestors      # get the intersection of ancestors of the two classes
        return !intersection.slice(0, intersection.index(Affect)).empty?  # slice the array elements preceding Affect: these will be common ancestors
    end                                                                   # if this array is empty after the slice, then there are no common ancestors

    def shares_keywords_with?(affect)
        @keywords.any? { |keyword| affect.keywords.include?(keyword) }
    end

    # Overwrite the modifiers with a new set
    # (Probably only used when loading existing affects from database)
    def overwrite_modifiers(modifiers)
        if modifiers
            @modifiers = {}
            modifiers.each do |stat, value|
                @modifiers[stat.to_stat] = value
            end
        else
            @modifiers = nil
        end
    end

    # Overwrite the data with a new hash
    # (Also probably only used when loading existing affects from the database)
    def overwrite_data(data)
        if !data
            @data = nil
            return
        end
        if !@data
            @data = {}
        end
        data.each do |key, value|
            @data[key] = value
        end
    end

    def duration
        if @clear_time
            return @clear_time - Game.instance.frame_time
        end
        return nil
    end

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

    def id
        self.class.id || -1
    end

    # Class methods

    def name
        return self.class.affect_info[:name]
    end

    def keywords
        return self.class.affect_info[:keywords]
    end

    def application_type
        return self.class.affect_info[:application_type]
    end

    def self.affect_info
        return @info || @info = {
            name: "affect name",
            keywords: ["affect_keywords"],
            application_type: :global_overwrite,
            data: @data
        }
    end

    # affect ID methods
    def self.set_id(id)
        @id = id
    end

    def self.id
        @id
    end

    def self.set_data(data)
        @data = data
    end


end
