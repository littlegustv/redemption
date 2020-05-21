class Group < GameObject

	attr_reader :joined, :invited

	def initialize( creator )
		@invited = []
		@joined = [ creator ]
	end

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
	end

end