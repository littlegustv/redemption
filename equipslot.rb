require_relative 'inventory'

# A slot for a single equipped item
class EquipSlot

    attr_reader :item
    attr_reader :owner
    attr_reader :equip_slot_info

    def initialize(owner, equip_slot_info)
        @owner = owner          # the room/mobile/item that contains these items
        @equip_slot_info = equip_slot_info
        @item = nil             # the item that is equipped in this slot (or nil)
    end

    def equip_message
        @equip_slot_info.equip_message
    end

    def list_prefix
        @equip_slot_info.list_prefix
    end

    def wear_locations
        @equip_slot_info.wear_locations
    end

    def items
        log "EquipSlot items being accessed: #{self.owner.name}"
        return nil
    end

    # Removes an item from this EquipSlot - Don't call this method directly!
    # Use item.move(new_inventory) instead.
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
    end

    # Adds an item to this EquipSlot - Don't call this method directly!
    # Use item.move(new_inventory) instead.
    def add_item(item)
        if @item
            log("Item is already equipped in EquipSlot.")
            return
        end
        @item = item
    end

    def empty?
        return item.nil?
    end

end
