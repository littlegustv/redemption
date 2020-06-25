#
# The place where a mobile can equip a single item. Contains an Item (or nil), a
# reference to its owner, and a reference to its EquipSlotInfo object, where
# it gets its equip message string, wear_locations, etc. from.
#
class EquipSlot

    # @return [Item, nil] THe item equipped in this slot, or `nil` if there isn't one.
    attr_reader :item

    # @return [Mobile] The Mobile who is the owner of this slot.
    attr_reader :owner

    #
    # EquipSlot Initializer.
    #
    # @param [Mobile] owner The mobile who owns this equip slot.
    # @param [EquipSlotInfo] equip_slot_info The EquipSlotInfo for this object.
    #
    def initialize(owner, equip_slot_info)
        @owner = owner          # the room/mobile/item that contains these items
        @equip_slot_info = equip_slot_info
        @item = nil             # the item that is equipped in this slot (or nil)
    end

    #
    # The equip message for this object, eg:
    #
    #    "0<N> wields 1<n>."
    #
    # @return [String] The equip message.
    #
    def equip_message
        @equip_slot_info.equip_message
    end

    #
    # The prefix in the equipment list for this equip slot, eg:
    #
    #   "held in hand"
    #
    # @return [String] The list prefix.
    #
    def list_prefix
        @equip_slot_info.list_prefix
    end

    #
    # The wear locations for this equip slot.
    #
    # @return [Array<WearLocation>] The wear locations.
    #
    def wear_locations
        @equip_slot_info.wear_locations
    end

    #
    # Removes an item from this EquipSlot - Don't call this method directly!
    # Use `item.move(new_inventory)` instead.
    #
    # @param [Item] item The item to remove from the equip slot.
    #
    # @return [nil]
    #
    def remove_item(item)
        if !@item
            log("Nothing is equipped in that EquipSlot.")
            return
        end
        if @item != item
            log("Item being removed from EquipSlot is not the same as already equipped item.")
            return
        end
        @item = nil if @item == item
        return
    end

    #
    # Adds an item to this EquipSlot - Don't call this method directly!
    # Use item.move(new_inventory) instead.
    #
    # @param [Item] item The item to add to the equipment slot.
    #
    # @return [nil]
    #
    def add_item(item)
        if @item
            log("Item is already equipped in EquipSlot.")
            return
        end
        @item = item
        return
    end

    #
    # Returns true if the slot is empty, or false if there is an item equipped.
    #
    # @return [Boolean] True if there is no item, otherwise false.
    #
    def empty?
        return item.nil?
    end

end
