# This class is where ALL items in the game end up being stored

class Inventory

    attr_reader :items
    attr_reader :item_count
    attr_reader :owner

    def initialize(owner)
        @owner = owner          # the room/mobile/item that contains these items
        @items = []             # List of items in this inventory
        @item_count = {}        # Item count hash (uses :id as key)
    end

    def show(observer:, long: false)
        ids_shown = []
        lines = []
        targets = Game.instance.target({ list: self.items, visible_to: observer, quantity: 'all' })
        targets.each do |item|
            if ids_shown.include?(item.id)
                next
            end
            quantity = targets.select{ |t| t.id == item.id }.length
            quantity_string = quantity > 1 ? "(#{quantity.to_s.lpad(2)})" : "    "
            if long
                lines << "#{quantity_string} #{item.long}"
            else
                lines << "#{quantity_string} #{item.name}"
            end
            ids_shown << item.id
        end
        return lines.join("\n")
    end

    # Removes an item from this inventory - Don't call this directly!
    # Use item.move(new_inventory) instead.
    def remove_item(item)
        @item_count[item.id] = @item_count[item.id].to_i - 1
        @item_count.delete(item.id) if item_count[item.id] <= 0
        @items.delete(item)
    end

    # Adds an item to this inventory - Don't call this method directly!
    # Use item.move(new_inventory) instead.
    def add_item(item)
        @item_count[item.id] = @item_count[item.id].to_i + 1
        @item_count.delete(item.id) if item_count[item.id] <= 0
        @items.unshift(item)
    end

    def show_with_categories(observer:, long: false)
        Game.instance.target({ list: self.items, :not => looker, visible_to: looker, quantity: 'all' }).map{ |t| "\n      #{t.long}" }.join
    end

    # returns the number of items
    def count
        return @items.count
    end

    def length
        return count
    end

    def empty?
        return count == 0
    end

end
