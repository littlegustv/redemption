class Mobile < GameObject

	attr_accessor :room, :target

	@target

	def initialize( name, game, room )
		@room = room
		@attack_speed = rand(2...4)
		@hitpoints = 500
		@hitroll = rand(5...7)
		@noun = ["entangle", "grep", "strangle", "pierce", "smother", "flaming bite"].sample
		super name, game
	end

	def update( elapsed )
		super elapsed
	end

	def fight( attacker )
		@game.broadcast "#{@name} yells 'Help I am being attacked by #{ attacker.name }!", @game.target({ not: self })
		output "You yell 'Help I am being attacked by #{ attacker.name }!"
		if @target.nil?
			@target = attacker
		end
	end

	def combat
		if @target
			to_me = []
			to_target = []
			to_room = []
			@attack_speed.times do |attack|
				if rand(0...10) < @hitroll
					damage = rand(1...20)
				else
					damage = 0
				end
				m, t, r = hit damage
				to_me.push m
				to_target.push t
				to_room.push r
			end
			output to_me.join("\n")
			@target.output to_target.join("\n")
			@game.broadcast to_room.join("\n"), @game.target({ not: [ self, @target ], room: @room })
		end
	end

	def hit( damage )
		decorators = Constants::DAMAGE[damage]
		@target.damage( damage )		
		["Your #{decorators[2]} #{@noun} #{decorators[1]} #{@target.name}", "#{@name}'s' #{decorators[2]} #{@noun} #{decorators[1]} you", "#{@name}'s' #{decorators[2]} #{@noun} #{decorators[1]} #{@target.name}"]
	end

	def damage( damage )
		@hitpoints -= damage
		die if @hitpoints <= 0
	end

	def die
		output "You have been KILLED!"
		@game.broadcast "#{@name} has been KILLED.", @game.target({ not: [ self ] })
		@target = nil
		@game.target({ target: self }).each { |t| t.target = nil }
	end

end