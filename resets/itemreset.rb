class ItemReset < Reset

    attr_reader :item_id
    attr_reader :timer
    attr_reader :child_resets

    def initialize(item_id, timer, equipped = nil, room_id = nil)
        super(timer)
        @item_id = item_id
        @child_resets = nil
        @equipped = equipped
        @room_id = room_id
        @owner = nil
    end

    def add_child_reset(child_reset)
        if !@child_resets
            @child_resets = []
        end
        @child_resets << child_reset
    end

    def pop(owner = nil)
        owner = (owner || @owner)
        @owner = nil
        if @room_id
            owner = Game.instance.rooms.dig(@room_id)
        end
        if !owner
            log "Invalid owner in item reset: item_id #{@item_id}"
            return false
        end
        if !owner.active # don't load items onto inactive objects
            return false
        end
        inventory = (owner || @owner).inventory

        model = Game.instance.item_models.dig(@item_id)
        if !model
            log "Invalid owner in item reset: item_id: #{@item_id} owner: #{owner.name}"
            return false
        end

        item = Game.instance.load_item(model, inventory, self)

        if @equipped
            owner.wear(item, true)
        end
        if @child_resets && item.is_a?(Container)
            @child_resets.to_a.each do |reset|
                reset.pop(item)
                reset.deactivate
            end
        end

        return true
    end

    def activate(instant = false, owner = nil)
        @owner = owner
        super(instant)
    end

    def deactivate
        super
        @child_resets.to_a.each do |reset|
            reset.deactivate
        end
    end

end
