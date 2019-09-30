
module MobileItem

    # returns true if the mobile can wear a given item
    def can_wear(item:, silent: false)
        return true
    end

    # returns true if mobile can unwear a given item
    def can_unwear(item:, silent: false)
        return true
    end

    # wear an item
    def wear( item:, silent: false )
        if !item
            log ("Nil item passed into Mobile.wear #{name}")
            return false
        end
        if !can_wear(item: item, silent: silent)
            return false
        end
        @equip_slots.each do |equip_slot|   # first try to find empty slots
            if item.wear_flags.include?(equip_slot.wear_flag) && !equip_slot.item
                if !silent
                    output(equip_slot.equip_message_self, [item])
                    broadcast(equip_slot.equip_message_others, target({ :not => self, :list => @room.occupants }), [self, item])
                end
                item.move(equip_slot)
                return true
            end
        end
        @equip_slots.each do |equip_slot|   # then try to find used slots
            if item.wear_flags.include?(equip_slot.wear_flag) && equip_slot.item
                if unwear(item: equip_slot.item, silent: silent)
                    if !silent
                        output(equip_slot.equip_message_self, [item])
                        broadcast(equip_slot.equip_message_others, target({ :not => self, :list => @room.occupants }), [self, item])
                    end
                    item.move(equip_slot)
                    return true
                end
            end
        end
        if !silent
            output "You can't wear that."
        end
        return false
    end

    # remove an item that is equipped
    def unwear( item:, silent: false )
        if !item
            log ("Nil item passed into Mobile.unwear #{name}")
            return false
        end
        if !can_unwear(item: item, silent: silent)
            return false
        end
        if !silent
            output("You stop using %s.", [item])
            broadcast("%s stops using %s.", target({ :not => self, :list => @room.occupants }), [self, item])
        end
        item.move(self.inventory)
        return true
    end

    # Returns an array of items that are held by @equip_slots
    def equipment
        return @equip_slots.select(&:item).map(&:item)
    end

    # return an array of equipped items in equip_slots with the 'wield' wear flag
    def wielded
        return @equip_slots.select{ |equip_slot| equip_slot.item && equip_slot.wear_flag == "wield" }.map(&:item)
    end

    def get_item(item)
        if !item.wear_flags.include? "take"
            output "You can't take #{ item }"
        end
        if Item === (container = item.parent_inventory.owner)
            output("You get %s from %s.", [item, container])
            broadcast("%s gets %s from %s.", target({ :not => self, :list => @room.occupants }), [self, item, container])
        else
            output("You get %s.", [item])
            broadcast("%s gets %s.", target({ :not => self, :list => @room.occupants }), [self, item])
        end
        item.move(@inventory)
    end

    def give_item(item, mobile)
        output("You give %s to %s.", [item, mobile])
        mobile.output("%s gives you %s.", [self, item])
        broadcast("%s gives %s to %s.", target({ :not => [self, mobile], :list => @room.occupants }), [self, item, mobile])
        item.move(mobile.inventory)
    end

    def drop_item(item)
        output("You drop %s.", [item])
        broadcast("%s drops %s.", target({ :not => self, :list => @room.occupants }), [self, item])
        item.move(@room.inventory)
    end

    def put_item(item, inventory)
        container = inventory.owner
        output("You put %s in %s.", [item, container])
        broadcast("%s puts %s in %s.", target({ :not => self, :list => @room.occupants }), [self, item, container])
        item.move(inventory)
    end

    def items
        @inventory.items + equipment
    end

end
