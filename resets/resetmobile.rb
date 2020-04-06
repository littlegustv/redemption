
class ResetMobile < Reset

    attr_reader :active, :pop_time

    def initialize( room_id, mobile_id, timer, chance )
        super(timer, chance)
        @room_id = room_id
        @mobile_id = mobile_id
    end

    ## Try to reset.
    # Returns true (@chance)% of the time.
    # Marks as inactive is successful.
    def pop
        room = Game.instance.rooms.dig(@room_id)
        if !room # invalid room
            log "Invalid room id in reset: room_id:#{@room_id}, mobile_id:#{@mobile_id}"
            return false
        end
        Game.instance.load_mob(@mobile_id, room, self)
        return true
    end


end
