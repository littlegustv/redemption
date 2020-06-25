#
# The Mobile Group object. This is how mobiles band together and cooperate!
#
class Group < GameObject

	# @return [Array<Mobile>] The mobiles invited to the group.
	attr_reader :joined
	
	# @return [Array<Mobile>] The mobiles currently in the group.
	attr_reader :invited

	#
	# Group initialization.
	#
	# @param [Mobile] creator The creator of the group.
	#
	def initialize( creator )
		@invited = []
		@joined = [ creator ]
	end

	#
	# Outputs a string to an actor describing this group
	#
	# @param [GameObject] actor The actor observing the group.
	#
	# @return [nil]
	#
	def output( actor )
		actor.output "#{actor}'s Group:"
		@joined.each do |member|
			actor.output "[#{member.level.to_s.lpad(2)}  #{member.mobile_class.name.capitalize_first.lpad(10)} ] #{member.name.rpad(15)} #{member.health}/ #{member.max_health} hp  #{member.mana} #{member.max_mana} mana  #{member.movement}/ #{member.max_movement} mv #{member.experience_to_level} tnl"
		end
		
		if @invited.count > 0
			actor.output "\n{CInvited:{x"
			@invited.each do |invitee|
				actor.output "#{invitee}"
			end
		end
		return
	end

	#
	# Returns the size of the group as an integer.
	#
	# @return [Integer] The size of the group.
	#
	def size
		return @joined.length
	end

	#
	# Alias for Group#size.
	#
	# @return [Integer] The size of the group.
	#
	def count
		return self.size
	end

	#
	# Iterates over each member of the group, executing a given block for each group member.
	#
	# @return [Array<Mobile>] The joined group members.
	#
	def each
		i = 0
		while i < @joined.length
			yield @joined[i]
			i += 1
		end
		return @joined
	end

end