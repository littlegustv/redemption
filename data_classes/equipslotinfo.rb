#
# The EquipSlotInfo data class.
#
class EquipSlotInfo < DataObject

    # @return [String] The message displayed when an EquipSlot with this EquipSlotInfo is used to requip an item.
    attr_reader :equip_message

    # @return [String] The string that displays before the item name in an equipment list, eg. `"worn on feet"`.
    attr_reader :list_prefix

    # @return [Array<WearLocation>] The wear locations for this EquipSlotInfo as an Array.
    attr_reader :wear_locations

    def initialize(row)
        super(row[:id], nil, nil)
        @equip_message = row[:equip_message]
        @list_prefix = row[:list_prefix]
        @wear_locations = []
    end


end
