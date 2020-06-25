#
# The Item Reset generates a new Item when it pops.
#
class ItemReset < Reset

    # @return [Integer] The ID of the item to generate with the reset.
    attr_reader :item_id

    # @return [Array<ItemReset>, nil] The child resets of this reset, or nil if there are none.
    attr_reader :child_resets

    def initialize(item_id, timer, equipped = nil, room_id = nil)
        super(timer)
        @item_id = item_id
        @model = Game.instance.item_models.dig(@item_id)
        @child_resets = nil
        @equipped = equipped
        @room_id = room_id
        @owner = nil
    end

    #
    # Give this reset a child item reset to `pop` when this reset pops.
    #
    # @param [ItemReset] child_reset The child item reset.
    #
    # @return [nil]
    #
    def add_child_reset(child_reset)
        if !@child_resets
            @child_resets = []
        end
        @child_resets << child_reset
        return 
    end

    #
    # Pops the item reset. Generates a new item and recursively pops child
    # resets as needed, filling inventories. The reset will prioritize an
    # owner being passed in as an argument, but will fall back on the owner
    # passed in at activation.
    # If this Reset had an owner set, at activation, it will be reset to `nil`
    # after the pop.
    #
    # @param [GameObject] owner The owner of the item to generate: the item,
    # mobile, room, etc. whose inventory the item wil 
    #
    # @return [Boolean] True if the reset was successful, otherwise false.
    #
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
        inventory = owner.inventory

        if !@model
            log "Invalid owner in item reset: item_id: #{@item_id} owner: #{owner.name}"
            return false
        end

        item = Game.instance.load_item(@model, inventory, self)

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

    #
    # Actviate this reset.
    #
    # @param [Boolean] instant Whether or not the reset should pop instantly.
    # @param [GameObject] owner The owner of the object-to-be, be it a room, mobile, container, etc.
    #
    # @return [nil]
    #
    def activate(instant = false, owner = nil)
        @owner = owner
        super(instant)
        return
    end

    #
    # Deactivates this item reset. Deactivates child resets and then calls `Reset#deactivate`.
    #
    # @return [nil]
    #
    def deactivate
        super
        @child_resets.to_a.each do |reset|
            reset.deactivate
        end
        return
    end

end
