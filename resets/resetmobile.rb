
class ResetMobile

    attr_reader :active, :pop_time

    def initialize( room_id, mobile_id, timer, chance )
        # @id = data[:id].to_i # not necessary?
        @room_id = room_id
        @mobile_id = mobile_id
        @timer = timer / 100
        @chance = chance
        @pop_time = 0
        @active = true
    end

    ## Try to reset.
    # Returns true (@chance)% of the time.
    # Marks as inactive is successful.
    def pop
        if @chance != 100 && dice(1, 100) > @chance
            @pop_time += @timer
            return false
        end
        # marking as inactive - if anything goes wrong from here on out, the reset won't activate again!
        @active = false
        room = Game.instance.rooms.dig(@room_id)
        if !room # invalid room
            log "Invalid room id in reset: room_id:#{@room_id}, mobile_id:#{@mobile_id}"
            return true
        end
        Game.instance.load_mob(@mobile_id, room, self)
        return true
    end

    def activate
        @pop_time = Time.now + @timer
        @active = true
        Game.instance.activate_reset(self)
    end

end
