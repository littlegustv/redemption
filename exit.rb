#
# EXits are the objects that link rooms together. Exits are GameObjects.
#
# A room with a two-way link to another room has two exits. These exits are
# linked to one another with their `pair` attribute.
#
# Exits can have a reset to return them to an inital state (door closed, etc).
#
class Exit < GameObject

    # @return [Room, nil] The room that this exit belongs to.
    attr_accessor :origin

    # @return [Room, nil] the Room object that this exit leads to
    attr_accessor :destination

    # @return [Direction, nil] The direction of this exit, or nil if it has none.
    attr_reader :direction

    # @return [Exit, nil] The mirrored exit for this one, or nil if there isn't one.
    attr_reader :pair

    # @return [Boolean] Whether or not the door is closed.
    attr_accessor :closed

    # @return [Boolean] Whether or not the door is locked.
    attr_accessor :locked

    # @return [Boolean] Whether or not the door lock can be picked.
    attr_reader :pickproof

	#
    # Exit initializer.
    #
    # @param [Direction, nil] direction The direction of the exit or `nil`.
    # @param [Room, nil] origin The origin room or `nil`.
    # @param [Room] destination The destination room.
    # @param [String] keywords The keywords as a String.
    # @param [String] name The name of the exit.
    # @param [String] short_description The short description.
    # @param [Boolean] door Whether or not the exit has a door.
    # @param [Integer, nil] key_id The ID of the key object.
    # @param [Boolean] closed Whether or not the door is closed.
    # @param [Boolean] locked Whether or not the door is locked.
    # @param [Boolean] pickproof Whether or not the door's lock can be picked.
    # @param [Boolean] passproof Whether or not the door can be passdoor'd thru on.
    # @param [Boolean] nonspatial Whether or not the door is spatial
    # @param [Float, nil] reset_timer The reset timer for the door state, or `nil`.
    # @param [Integer, nil] id The ID for the exit, or `nil`.
    #
    def initialize(
        direction,
        origin,
        destination,
        keywords,
        name,
        short_description = "".freeze,
        door = false,
        key_id = nil,
        closed = false,
        locked = false,
        pickproof = false,
        passproof = false,
        nonspatial = false,
        reset_timer = nil,
        id = nil
    )
        super(name, keywords )
        @id = id
		@direction = direction
		@origin = origin
        if @origin
            @origin.add_exit(self)
        end
		@destination = destination
        if @destination
            @destination.add_entrance(self)
        end
		@short_description = short_description.to_s
        @door = door
		@key_id = key_id
        @closed = closed
        @locked = locked
        @pickproof = pickproof
        @passproof = passproof
        @nonspatial = nonspatial
        @reset = nil
        if reset_timer
            @reset = ExitReset.new(self, @closed, @locked, reset_timer )
        end
		@pair = nil
	end

    #
    # Destroys this exit. Remove it as an exit and entrance from its origin and destination
    # respectively.
    #
    # @return [nil]
    #
    def destroy
        if @origin
            @origin.remove_exit(self)
            @origin = nil
        end
        if @destination
            @destination.remove_entrance(self)
            @destination = nil
        end
        super
        return
    end

	#
    # Link this exit to another one. The other exit will also become linked.
    # Fails if this exit is already paired.
    #
    # @param [Exit] other_exit The exit to link to.
    #
    # @return [nil]
    #
    def add_pair( other_exit )
		if @pair.nil?
			@pair = other_exit
			other_exit.add_pair( self )
        end
        return
	end

	#
    # Returns a string representation of the Exit. If the exit has a closed door, this will
    # surround the name in a colour.
    #
    #   exit.to_s # => "{cwest{x"
    #
    # @return [String] The string representation.
    #
    def to_s
        if !@direction
            return ""
        end
		return @closed ? "{c(#{@direction.name}){x" : "#{@direction.name}"
	end

    #
    # The name of the exit, or "door" if it has no name.
    #
    # @return [String] The name.
    #
    def name
        @name || "door"
    end

    
	#
    # Locks the door from the perspective of a mobile. Returns success.
    #
    # @param [Mobile] actor The mobile doing the locking.
    # @param [Boolean] silent True to suppress messages, otherwise false.
    #
    # @return [Boolean] True if the lock was locked.
    #
    def lock( actor, silent = false )
		if not @closed
			actor.output "You can't lock it while it's open!" unless silent
			return false
		elsif @locked
			actor.output "It is already locked." unless silent
			return false
		elsif actor.items.map(&:id).include?(@key_id)
            @reset.activate if @reset
			unless silent
				actor.output "Click."
                if @direction
	                (actor.room.occupants - [actor]).each_output "0<N> locks the #{self.name} to the #{@direction.name}.", [actor]
                else
                    (actor.room.occupants - [actor]).each_output "0<N> locks #{self.name}.", [actor]
                end
			end

			@locked = true
			@pair.lock( actor, silent: true ) if @pair
			return true
		else
			actor.output "You lack the key." unless silent
			return false
		end
	end

	#
    # Unlocks the door from the perspective of a mobile. Returns success.
    #
    # @param [Mobile] actor The mobile doing the unlocking.
    # @param [Boolean] silent True to suppress messages, otherwise false.
    # @param [Boolean] override True if the key should be ignored.
    # @return [Boolean] True if the door was unlocked.
    #
    def unlock( actor, silent = false, override = false )
		if not @locked
			actor.output "It isn't locked." unless silent
			return false
		elsif actor.items.map(&:id).include?(@key_id) || override
            @reset.activate if @reset
			unless silent
				actor.output "Click."
                if @direction
	                (actor.room.occupants - [actor]).each_output "0<N> unlocks the #{self.name} to the #{@direction.name}.", [actor]
                else
                    (actor.room.occupants - [actor]).each_output "0<N> unlocks #{self.name}.", [actor]
                end
			end

			@locked = false
			@pair.unlock( actor, true, override ) if @pair
			return true
		else
			actor.output "You lack the key." unless silent
			return false
		end
	end

	#
    # Opens the door from the perspective of a mobile. Returns success.
    #
    # @param [Mobile] actor The mobile doing the opening.
    # @param [Boolean] silent True to suppress messages, otherwise false.
    # @param [Boolean] override TODO: figure out what override does?
    #
    # @return [Boolean] True if the door was opened, otherwise false.
    #
    def open( actor, silent = false, override = false )
		if @locked
			actor.output "It's locked." unless silent
			return false
		elsif @closed
            @reset.activate if @reset
			unless silent
				actor.output "You open the #{self.name}."
				(actor.room.occupants - [actor]).each_output "0<N> opens the #{self.name}", [actor]
			end

			@closed = false
			@pair.open( actor, true, override ) if @pair
			return true
		else
			actor.output "It's already open." unless silent
			return false
		end
	end

	#
    # Closes the door from the perspective of a mobile. Returns success.
    #
    # @param [Mobile] actor The mobile doing the closing.
    # @param [Boolean] silent True to suppress messages, otherwise false.
    #
    # @return [Boolean] True if the door was closed, otherwise false.
    #
    def close( actor, silent = false )
		if !@closed
			@closed = true
			@pair.close( actor, silent: true ) if @pair

			unless silent
				actor.output "You close the #{name}."
				(actor.room.occupants - [actor]).each_output "0<N> closes #{short_description}", [actor]
			end

			return true
		elsif @closed
			actor.output "It's already closed." unless silent
			return false
		else
			actor.output "You can't close that." unless silent
			return false
		end
	end

	#
    # Take a mobile and move it through this exit to the exit's destination.
    # Returns success.
    #
    # @param [Mobile] mobile The mobile to move.
    #
    # @return [Boolean] True if the mobile was moved, otherwise false.
    #
    def move( mobile )
		if @closed && !mobile.affected?("pass door")
			mobile.output "The #{name} is closed."
			return false
        elsif mobile.affected?("pass door") && @passproof
            mobile.output "You can't pass through the #{self.name}."
            return false
		else
            portal = @direction.nil?
            sneaking = mobile.affected?("sneak")
            leave_string = ""
            if portal
                leave_string = "0<N> steps into 1<n>."
                mobile.output("You step into 0<n>.", [self]) unless sneaking
            else
                leave_string = "0<N> leaves #{@direction.name}."
            end
            (mobile.room.occupants - [mobile]).each_output(leave_string, [mobile, self]) unless sneaking
            old_room = mobile.room
            mobile.move_to_room( @destination )
            if old_room
                old_room.occupants.select { |t| t.position != :sleeping && t.responds_to_event(:observe_mobile_use_exit) }.each do |t|
                    Game.instance.fire_event( t, :observe_mobile_use_exit, {mobile: mobile, exit: self } )
                end
            end
            arrive_string = ""
            if portal
                arrive_string = "0<N> has arrived through 1<n>."
            else
                arrive_string = "0<N> has arrived."
            end
            (mobile.room.occupants - [mobile]).each_output arrive_string, [mobile, self] unless sneaking
		end
        return true
	end

    #
    # Set the destination of the exit after initialization. Clears existing destination if
    # there is one. Used by portals.
    #
    # @param [Room] destination The new destination room.
    #
    # @return [nil]
    #
    def set_destination(destination)
        if @destination
            @destination.remove_entrance(self)
        end
        @destination = destination
        if @destination
            @destination.add_entrance(self)
        end
        return
    end 

end
