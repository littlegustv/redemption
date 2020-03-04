class Exit < GameObject

	attr_reader :destination, :origin, :pair

	def initialize( direction, origin, destination, flags, key_id, keywords, description = nil )
		@direction = direction
		@origin = origin
		@destination = destination
		@flags = flags
		@key_id = key_id == 0 ? nil : key_id

		@closed = @flags.include?("door")
		@locked = @key_id != nil

		@description = description.to_s
		@pair = nil
		super( direction, keywords )
	end

	def add_pair( exit )
		if @pair.nil?
			@pair = exit
			exit.add_pair( self )
		end
	end

	# could be replaced with the tokenizing method, if needed
    def fuzzy_match( query )
        query.to_a.all?{ |q|
            @keywords.any?{ |keyword|
                keyword.to_s.fuzzy_match( q )
            }
        }
    end

	def to_s
		@closed ? "{c(#{@direction}){x" : "#{@direction}"
	end

	def short
		(@keywords.first || "door")
	end

	def lock( actor, silent: false )
		if not @closed
			actor.output "You can't lock it while it's open!" unless silent
			return false
		elsif @locked
			actor.output "It is already locked." unless silent
			return false
		elsif actor.items.map(&:id).include?(@key_id)

			unless silent
				actor.output "Click."
				actor.broadcast "%s locks the #{short} to the #{@direction}.", actor.room.occupants - [actor], [actor]
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

			unless silent
				actor.output "Click."
				actor.broadcast "%s unlocks the #{short} to the #{@direction}.", actor.room.occupants - [actor], [actor]
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

			unless silent
				actor.output "You open #{short}"
				actor.broadcast "%s opens #{short}", actor.room.occupants - [actor], [actor]
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
		if !@closed && @flags.include?("door")
			@closed = true
			@pair.close( actor, silent: true ) if @pair

			unless silent
				actor.output "You close #{short}"
				actor.broadcast "%s closes #{short}", actor.room.occupants - [actor], [actor]
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
			mobile.output "The %s is closed.", [ short ]
			return false
		else
            mobile.move_to_room( @destination )
            return true
		end
	end

end
