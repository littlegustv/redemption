class ItemReset < Reset

    attr_reader :item_id
    attr_reader :quantity
    attr_reader :child_reset_group_id

    def initialize(item_id, child_resets, timer, equipped = nil)
        super(timer)
        @item_id = item_id
        @child_resets = child_resets
        @equipped = equipped
        @owner = nil
    end

    def pop(owner = nil)
        owner = (owner || @owner)
        @owner = nil
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

        if @child_resets
            @child_resets.each do |reset|
                reset.pop(item)
            end
        end
        if @equipped
            owner.wear(item, true)
        end

        return true
    end

    def activate(instant = false, owner = nil)
        @owner = owner
        super(instant)
    end

end
