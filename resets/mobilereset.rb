class MobileReset < Reset

    attr_accessor :item_resets

    def initialize( room_id, mobile_id, timer )
        super(timer)
        @room_id = room_id
        @mobile_id = mobile_id
        @item_resets = nil
    end

    ## Try to reset.
    def pop
        room = Game.instance.rooms.dig(@room_id)
        model = Game.instance.mobile_models.dig(@mobile_id)
        if !room # invalid room
            log "Invalid room id in mobile reset: room_id:#{@room_id}, mobile_id:#{@mobile_id}"
            return false
        end
        if !model
            log "Invalid mobile id in mobile reset: room_id:#{@room_id}, mobile_id:#{@mobile_id}"
            return false
        end

        mob = Game.instance.load_mob(model, room, self)
        @item_resets.to_a.each do |reset|
            reset.pop(mob)
        end
        return true
    end


end
