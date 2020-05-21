class Exit < GameObject

	attr_accessor :destination
    attr_accessor :closed
    attr_accessor :locked
    attr_reader :origin
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
		@destination = destination
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
    end

	def add_pair( exit )
		if @pair.nil?
			@pair = exit
			exit.add_pair( self )
		end
	end

	def to_s
		@closed ? "{c(#{@direction.name}){x" : "#{@direction.name}"
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
				(actor.room.occupants - [actor]).each_output "0<N> locks the #{self.name} to the #{@direction.name}.", [actor]
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
				(actor.room.occupants - [actor]).each_output "0<N> unlocks the #{self.name} to the #{@direction.name}.", [actor]
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
				actor.output "You open the #{name}."
				(actor.room.occupants - [actor]).each_output "0<N> opens #{short_description}", [actor]
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
            mobile.move_to_room( @destination )
            return true
		end
	end

    def db_source_type_id
        return 7
    end

end
