require_relative 'inventory'

# A slot for a single equipped item
class EquipSlot

    attr_reader :item
    attr_reader :owner

    def initialize(slot, owner)
        @owner = owner          # the room/mobile/item that contains these items
        @slot = slot
        @item = nil                                     # the item that is equipped in this slot (or nil)
    end

    def equip_message
        Game.instance.equip_slot_data.dig( @slot, :equip_message )
    end

    def list_prefix
        Game.instance.equip_slot_data.dig( @slot, :list_prefix )
    end

    def wear_flag
        Game.instance.equip_slot_data.dig( @slot, :wear_flag )
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
