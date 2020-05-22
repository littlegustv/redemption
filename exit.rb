class Exit < GameObject

	attr_accessor :destination
    attr_accessor :closed
    attr_accessor :locked
    attr_accessor :origin
    attr_reader :direction
    attr_reader :pair
    attr_reader :pickproof

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
        id = 0
    )
        super(name, Game.instance.global_keyword_set_for_keyword_string(keywords.freeze) )
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

    def destroy
        super
        if @origin
            @origin.remove_exit(self)
        end
        if @destination
            @destination.remove_entrance(self)
        end
    end

	def add_pair( exit )
		if @pair.nil?
			@pair = exit
			exit.add_pair( self )
		end
	end

	def to_s
        if !@direction
            return ""
        end
		return @closed ? "{c(#{@direction.name}){x" : "#{@direction.name}"
	end

    def name
        @name || "door"
    end

	def lock( actor, silent: false )
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

	def unlock( actor, silent: false, override: false )
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
			@pair.unlock( actor, silent: true, override: override ) if @pair
			return true
		else
			actor.output "You lack the key." unless silent
			return false
		end
	end

	def open( actor, silent: false, override: false )
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
			@pair.open( actor, silent: true, override: override ) if @pair
			return true
		else
			actor.output "It's already open." unless silent
			return false
		end
	end

	def close( actor, silent: false )
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
                old_room.occupants.select { |t| t.position != :sleeping && t.responds_to_event(:event_observe_mobile_use_exit) }.each do |t|
                    Game.instance.fire_event( t, :event_observe_mobile_use_exit, {mobile: mobile, exit: self } )
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

    def db_source_type_id
        return 7
    end

    def set_destination(destination)
        if @destination
            @destination.remove_entrance(self)
        end
        @destination = destination
        if @destination
            @destination.add_entrance(self)
        end
    end

end
