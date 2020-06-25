#
# This class is where ALL items in the game end up being stored (except items in EquipSlots!)
#
class Inventory

    # @return [GameObject] The owner of this inventory. Can be a Mobile, a Room, an Item, whatever!
    attr_reader :owner

    def initialize(owner)
        # @type [GameObject]
        @owner = owner          # the room/mobile/item that contains these items
        # @type [Array<Item>, nil]
        @items = nil             # List of items in this inventory
    end

    #
    # Shows the items in this inventory to a GameObject. Returns a string to output.
    #
    # @param [GameObject] observer The observer of the inventory.
    # @param [Boolean] short_description True to use short descriptions instead of names.
    # @param [String, nil] empty_value The value to return when no objects were observed.
    #
    # @return [String, nil] The list as a formatted string, or `empty_value` if no objects were observed.
    #
    def show(observer, short_description = false, empty_value = "")
        names_shown = []
        ids_shown = []
        lines = []
        targets = observer.target( list: items, quantity: "all")
        if targets.nil? || targets.empty?
            return empty_value
        end
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

    #
    # Removes an item from this inventory.
    # __Don't call this directly! Use__ `item.move(new_inventory)` __instead.__
    #
    # @param [Item] item The Item to remove.
    #
    # @return [nil]
    #
    def remove_item(item)
        @items.delete(item)
        if @items.empty?
            @items = nil
        end
        return
    end

    #
    # Adds an item to this inventory.
    # __Don't call this method directly! Use__ `item.move(new_inventory)` __instead.__
    #
    # @param [Item] item The Item to add.
    #
    # @return [nil]
    #
    def add_item(item)
        if @items
            @items.unshift(item)
        else
            @items = [item]
        end
        return
    end

    #
    # Show this inventory with categories. WIP
    #
    # @param [GameObject] observer The observer of the inventory.
    # @param [Boolean] short_description True if the output should use short_descriptions instead of names.
    # @param [String, nil] empty_value The value to return when no objects were observed.
    #
    # @return [String, nil] The list as a formatted string, or `empty_value` if no objects were observed.
    #
    def show_with_categories(observer, short_description = false, empty_value = "")
        observer.target(list: items, not: observer, quantity: "all").map{ |t| "\n      #{t.short_description}" }.join
    end

    #
    # Returns the number of items in this inventory.
    #
    # @return [Integer] The item count.
    #
    def count
        if @items
            return @items.count
        else
            return 0
        end
    end

    #
    # An alias for Inventory#count.
    #
    # @return [Integer] The item count.
    #
    def length
        return count
    end

    #
    # Returns true if the inventory is empty.
    #
    # @return [Boolean] True if the inventory is empty, otherwise false.
    #
    def empty?
        return @items == nil || @items.empty?
    end

    #
    # Retuns the objects in this inventory as an array.
    #
    # @return [Array<Item>] The items.
    #
    def items
        @items || []
    end

end
