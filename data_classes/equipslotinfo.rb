
class EquipSlotInfo

    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :equip_message
    attr_reader :list_prefix
    attr_reader :wear_locations

    def initialize(row)
        @id = row[:id]
        @name = row[:name]
        @symbol = row[:name].to_s.to_sym
        @equip_message = row[:equip_message]
        @list_prefix = row[:list_prefix]

        @wear_locations = Array.new
    end


end
