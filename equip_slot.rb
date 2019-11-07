require_relative 'inventory'

# A slot for a single equipped item
class EquipSlot

    # attr_reader :equip_message_self
    # attr_reader :equip_message_others
    # attr_reader :list_prefix
    # attr_reader :wear_flag
    attr_reader :item
    attr_reader :owner

    def initialize(slot, owner, game)
        @game = game            # reference to the game object
        @owner = owner          # the room/mobile/item that contains these items
        @slot = slot
        # @equip_message_self = equip_message_self        # String format for mobile doing the equipping
        # @equip_message_others = equip_message_others    # String format for others in the room
        # @list_prefix = list_prefix                      # ex. worn about body, worn on feet, etc
        # @wear_flag = wear_flag                          # wear_body, wear_wrist, etc
        @item = nil                                     # the item that is equipped in this slot (or nil)
    end

    def equip_message_self
        @game.equip_slot_data.dig( @slot, :equip_message_self )
    end

    def equip_message_others
        @game.equip_slot_data.dig( @slot, :equip_message_others )
    end

    def list_prefix
        @game.equip_slot_data.dig( @slot, :list_prefix )
    end

    def wear_flag
        @game.equip_slot_data.dig( @slot, :wear_flag )
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
