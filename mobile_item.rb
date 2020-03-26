module MobileItem

    # returns true if the mobile can wear a given item
    def can_wear(item:, silent: false)
        if item.level <= self.level
            return true
        else
            output "You must be level #{ item.level } to use 0<n>.", [item]
            (@room.occupants - [ self ]).each_output "0<N> tries to use 1<n> but is too inexperienced.", [ self, item ]
            return false
        end
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
        equip_slots.each do |equip_slot|   # first try to find empty slots
            if item.wear_flags.include?(equip_slot.wear_flag) && !equip_slot.item
                if !silent
                    @room.occupants.each_output(equip_slot.equip_message, [self, item])
                    if equip_slot.wear_flag == "wield"
                        if proficient( item.genre )
                            output "0<N> feels like a part of you!", [item]
                        else
                            output "You don't even know which end is up on 0<n>.", [item]
                        end
                    end
                end
                item.move(equip_slot)
                return true
            end
        end
        equip_slots.each do |equip_slot|   # then try to find used slots
            if item.wear_flags.include?(equip_slot.wear_flag) && equip_slot.item
                if unwear(item: equip_slot.item, silent: silent)
                    if !silent
                        @room.occupants.each_output(equip_slot.equip_message, [self, item])
                        if equip_slot.wear_flag == "wield"
                            if proficient( item.genre )
                                output "0<N> feels like a part of you!", [item]
                            else
                                output "You don't even know which end is up on 0<n>.", [item]
                            end
                        end
                    end
                    item.move(equip_slot)
                    return true
                end
            end
        end
        if !silent
            output "You can't wear that."
        end
        get_item(item, silent: true)
        return false
    end

    def wear_all
        self.equip_slots.select(&:empty?).each do |equip_slot|
            item = self.inventory.items.find{ |i| i.wear_flags.include?(equip_slot.wear_flag) }
            wear(item: item) if item
        end
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
            self.room.occupants.each_output "0<N> stop0<,s> using 1<n>.", [self, item]
        end
        get_item(item, silent: true)
        return true
    end

    # Returns a string showing this mobile's equipment to another.
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
    def equipment
        return self.equip_slots.select(&:item).map(&:item)
    end

    # return an array of equipped items in equip_slots with the 'wield' wear flag
    def wielded
        return self.equip_slots.select{ |equip_slot| equip_slot.item && equip_slot.wear_flag == "wield" }.map(&:item)
    end

    # return an array of equipped items in equip_slots with arbitrary wear flag
    def equipped( slot )
        return self.equip_slots.select{ |equip_slot| equip_slot.item && equip_slot.wear_flag == slot }.map(&:item)
    end

    def free?( slot )
        return self.equip_slots.any?{ |equip_slot| equip_slot.item.nil? && equip_slot.wear_flag == slot }
    end

    # puts an item into a container
    def put_item(item, container, silent: false)
        if item == container
            output "That would be a bad idea."
            return
        end
        output "You puts 0<n> in 1<n>.", [item, container] if !silent
        @room.occupants.each_output("0<N> put0<,s> 1<n> in 2<n>.", [self, item, container]) if !silent
        container.get_item(item)
        # if @inventory && @inventory.items.size == 0
        #     @inventory = nil
        # end
    end

    # Gets an item, regardless of where it is.
    def get_item(item, silent: false)
        if !item.wear_flags.include? "take"
            output "You can't take 0<n>.", [item]
            return
        end
        if item.parent_inventory && Item === (container = item.parent_inventory.owner)
            @room.occupants.each_output("0<N> get0<,s> 1<n> from 2<n>.", [self, item, container]) if !silent
        else
            @room.occupants.each_output("0<N> get0<,s> 1<n>.", [self, item]) if !silent
        end

        Game.instance.fire_event( self, :event_get_item, { actor: self, item: item } )

        # if !@inventory # no inventory, create one
        #     @inventory = Inventory.new(self)
        # end
        item.move(@inventory)
    end

    def give_item(item, mobile, silent: false)
        @room.occupants.each_output("0<N> give0<,s> 1<n> to 2<n>.", [self, item, mobile]) if !silent
        mobile.get_item(item, silent: true)
        # if @inventory && @inventory.items.size == 0
        #     @inventory = nil
        # end
    end

    def drop_item(item, silent: false)
        @room.occupants.each_output("0<N> drop0<,s> 1<n>.", [self, item]) if !silent
        @room.get_item(item)
        # if @inventory && @inventory.items.size == 0
        #     @inventory = nil
        # end
    end

    def equip_slots
        # data = {equip_slots: (@race_equip_slots + @class_equip_slots)}
        # Game.instance.fire_event(self, :event_get_equip_slots, data )
        return @race_equip_slots + @class_equip_slots
    end

    def items
        if @inventory
            return @inventory.items + equipment
        else
            return equipment
        end
    end

end
