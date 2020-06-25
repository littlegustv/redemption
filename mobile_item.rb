class Mobile

    #
    # Returns true if the mobile can wear a given item.
    #
    # @param [Item] item The Item in question.
    # @param [Boolean] silent True if this mobile shouldn't output messages describing failure to equip.
    #
    # @return [Boolean] True if the item can be worn.
    #
    def can_wear(item, silent = false)
        if item.level <= self.level
            return true
        else
            if !silent
                output "You must be level #{ item.level } to use 0<n>.", [item]
                (@room.occupants - [ self ]).each_output "0<N> tries to use 1<n> but is too inexperienced.", [ self, item ]
            end
            return false
        end
    end

    #
    # Returns true if mobile can unwear a given item.
    #
    # @param [Item] item The Item in question.
    # @param [Boolean] silent True if this mobile shouldn't output messages describing failure to remove.
    #
    # @return [Boolean] True if the item can be unworn.
    #
    def can_unwear(item, silent = false)
        return true
    end
    
    #
    # Make this Mobile wear an Item.
    #
    # @param [Item] item The Item to wear.
    # @param [Boolean] silent True if this Mobile shouldn't output wear messages.
    #
    # @return [Boolean] True if the item gets worn, otherwise false.
    #
    def wear( item, silent = false )
        if !item
            log ("Nil item passed into Mobile.wear #{name}")
            return false
        end
        if !can_wear(item, silent)
            return false
        end
        slots = self.equip_slots.select { |slot| (item.wear_locations & slot.wear_locations).size > 0 }
        slots.each do |equip_slot|   # first try to find empty slots
            if !equip_slot.item
                if !silent
                    @room.occupants.each_output(equip_slot.equip_message, [self, item])
                    if item.is_a?(Weapon)
                        if proficient( item.genre )
                            output "0<N> feels like a part of you!", [item]
                        else
                            output "You don't even know which end is up on 0<n>.", [item]
                        end
                    end
                end
                item.move(equip_slot)
                try_add_to_regen_mobs
                return true
            end
        end
        slots.each do |equip_slot|   # then try to find used slots
            if equip_slot.item
                if unwear(equip_slot.item, silent)
                    if !silent
                        @room.occupants.each_output(equip_slot.equip_message, [self, item])
                        if item.is_a?(Weapon)
                            if proficient( item.genre )
                                output "0<N> feels like a part of you!", [item]
                            else
                                output "You don't even know which end is up on 0<n>.", [item]
                            end
                        end
                    end
                    item.move(equip_slot)
                    try_add_to_regen_mobs
                    return true
                end
            end
        end
        if !silent
            output "You can't wear that."
        end
        get_item(item, true)
        return false
    end

    #
    # Try to equip an item in each EquipSlot of this Mobile using items in its Inventory.
    #
    # @return [nil]
    #
    def wear_all
        self.equip_slots.select(&:empty?).each do |equip_slot|
            item = self.inventory.items.find{ |i| (i.wear_locations & equip_slot.wear_locations).size > 0 }
            wear(item) if item
        end
        return
    end

    #
    # Remove an item that is equipped.
    #
    # @param [Item] item The item to remove.
    # @param [Boolean] silent True if this mobile shouldn't output unequip messages.
    #
    # @return [Boolean] True if the item was removed.
    #
    def unwear( item, silent = false )
        if !item
            log ("Nil item passed into Mobile.unwear #{name}")
            return false
        end
        if !can_unwear(item, silent)
            return false
        end
        if !silent
            self.room.occupants.each_output "0<N> stop0<,s> using 1<n>.", [self, item]
        end
        get_item(item, true)
        try_add_to_regen_mobs
        return true
    end

    # Returns a string showing this mobile's equipment to another.
    
    #
    # Returns a string showing this mobile's equipment to another GameObject.
    #
    # @param [GameObject] observer The observer.
    #
    # @return [String] The equipment list as a String.
    #
    def show_equipment(observer)
        objects = []
        lines = []
        count = 0
        self.equip_slots.each do |equip_slot|
            line = "<#{equip_slot.list_prefix}>".rpad(22)
            if equip_slot.item
                line << "#{count}<AN>"
                objects << equip_slot.item
                count = count + 1
            else
                if observer == self
                    line << "<<Nothing>>"
                else
                    next
                end
            end
            lines << line
        end
        observer.output(lines.join("\n"), objects)
    end

    # Returns an array of items that are held by @equip_slots
    
    #
    # Returns an array of Items that this item has equipped.
    #
    # @return [Array<Item>] The array of equipped items.
    #
    def equipment
        return self.equip_slots.select(&:item).map(&:item)
    end

    #
    # Returns an array of equipped Items with a given Item Class.
    #
    #   mobile.equipped(Weapon) # => [(A sword, A dagger)]
    #
    # @param [Class] item_class The item Class.
    #
    # @return [Array<Item>] The equipped items of a given class.
    #
    def equipped( item_class )
        return self.equip_slots.select{ |equip_slot| equip_slot.item && equip_slot.item.is_a?(item_class) }.map(&:item)
    end

    #
    # Returns true if this Mobile has an empty EquipSlot for a given WearLocation.
    #
    # @param [WearLocation, Symbol] wear_location The WearLocation, or its symbol.
    #
    # @return [Boolean] True if the mobile has an empty EquipSlot for the given WearLocation.
    #
    def free?( wear_location )
        wear_location = wear_location.to_wear_location
        return self.equip_slots.any?{ |equip_slot| equip_slot.item.nil? && equip_slot.wear_locations.include?(wear_location) }
    end

    # puts an item into a container
    
    #
    # Makes this Mobile put an Item into a Container.
    #
    # @param [Item] item The item to move.
    # @param [Container] container The Container to put the Item in.
    # @param [Boolean] silent True if the Mobile shouldn't output messages.
    #
    # @return [Boolean] True if the item was moved, otherwise false.
    #
    def put_item(item, container, silent = false)
        if item == container
            output "That would be a bad idea."
            return false
        end
        @room.occupants.each_output("0<N> put0<,s> 1<n> in 2<n>.", [self, item, container]) if !silent
        container.get_item(item)
        return true
    end

    # Gets an item, regardless of where it is.
    
    #
    # Makes this Mobile get an item.
    #
    # @param [Item] item The item to get.
    # @param [Boolean] silent True if the Mobile shouldn't send output messages.
    #
    # @return [Boolean] True if the item was moved, otherwise false.
    #
    def get_item(item, silent = false)
        if item.fixed
            output "You can't take 0<n>.", [item]
            return false
        end
        if item.parent_inventory && Item === (container = item.parent_inventory.owner)
            @room.occupants.each_output("0<N> get0<,s> 1<n> from 2<n>.", [self, item, container]) if !silent
        else
            @room.occupants.each_output("0<N> get0<,s> 1<n>.", [self, item]) if !silent
        end
        if responds_to_event(:get_item)
            Game.instance.fire_event( self, :get_item, { actor: self, item: item } )
        end

        item.move(@inventory)
        return true
    end

    #
    # Makes this Mobile give an Item to another Mobile
    #
    # @param [Item] item The item to give.
    # @param [Mobile] mobile The mobile to give the Item to.
    # @param [Boolean] silent True if this mobile shouldn't send output messages.
    #
    # @return [Boolean] True if the item was given.
    #
    def give_item(item, mobile, silent = false)
        @room.occupants.each_output("0<N> give0<,s> 1<n> to 2<n>.", [self, item, mobile]) if !silent
        mobile.get_item(item, true)
        return true
    end

    #
    # Makes this Mobile drop a given Item.
    #
    # @param [Item] item The Item to drop.
    # @param [Boolean] silent True if the mobile shouldn't send output messages.
    #
    # @return [Boolean] True if the item was dropped.
    #
    def drop_item(item, silent = false)
        if !room.active
            return false
        end
        @room.occupants.each_output("0<N> drop0<,s> 1<n>.", [self, item]) if !silent
        @room.get_item(item)
        return true
    end

    #
    # Returns the Array of all EquipSlots for this Mobile.
    #
    # @return [Array<EquipSlot>] The EquipSlots for this mobile.
    #
    def equip_slots
        # data = {equip_slots: (@race_equip_slots + @mobile_class_equip_slots)}
        # Game.instance.fire_event(self, :get_equip_slots, data )
        slots = []
        if @race_equip_slots && @race_equip_slots.any?
            slots += @race_equip_slots.to_a
        end
        if @mobile_class_equip_slots && @mobile_class_equip_slots.any?
            slots += @mobile_class_equip_slots.to_a
        end
        return slots
    end

    #
    # Returns the array of Items in this Mobile's Inventory and EquipSlots.
    #
    # @return [Array<Item>] The array of Items.
    #
    def items
        if @inventory
            return @inventory.items + equipment
        else
            return equipment
        end
    end

    #
    # Returns ALL items for this Mobile, including those within containers carried
    # by this mobile, recursively.
    #
    # @return [Array<Item>] The array of ALL Items.
    #
    def all_items
        results = []
        sub_items = self.items
        while sub_items.any? do
            results += sub_items
            sub_items = sub_items.select! { |i| i.is_a?(Container) }.map(&:items).flatten
        end
        return results
    end

end
