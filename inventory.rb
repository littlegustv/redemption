# This class is where ALL items in the game end up being stored

class Inventory

    attr_reader :owner

    def initialize(owner)
        @owner = owner          # the room/mobile/item that contains these items
        @items = nil             # List of items in this inventory
    end

    def show(observer:, short_description: false)
        names_shown = []
        ids_shown = []
        lines = []
        targets = Game.instance.target({ list: self.items.to_a, visible_to: observer, quantity: 'all' })
        targets.each do |item|
            name = (short_description) ? item.long_auras + item.short_description : item.long_auras + item.name
            if names_shown.include?(name) && ids_shown.include?(item.id)
                next
            end
            quantity = targets.select{ |t| t.id == item.id && ((short_description) ? t.long_auras + t.short_description : t.long_auras + t.name) == name }.length
            quantity_string = quantity > 1 ? "(#{quantity.to_s.lpad(2)})" : "    "
            lines << "#{quantity_string} #{name}"
            names_shown << name
            ids_shown << item.id
        end
        return lines.join("\n")
    end

    # Removes an item from this inventory - Don't call this directly!
    # Use item.move(new_inventory) instead.
    def remove_item(item)
        @items.delete(item)
        if @items.empty?
            @items = nil
        end
    end

    # Adds an item to this inventory - Don't call this method directly!
    # Use item.move(new_inventory) instead.
    def add_item(item)
        if @items
            @items.unshift(item)
        else
            @items = [item]
        end
    end

    def show_with_categories(observer:, short_description: false)
        Game.instance.target({ list: self.items.to_a, :not => looker, visible_to: looker, quantity: 'all' }).map{ |t| "\n      #{t.short_description}" }.join
    end

    # returns the number of items
    def count
        if @items
            return @items.count
        else
            return 0
        end
    end

    def length
        return count
    end

    def empty?
        return count == 0
    end

    #
    def items
        @items || []
    end

end
