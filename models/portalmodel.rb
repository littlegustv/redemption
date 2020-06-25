#
# The Model for Portal items.
#
class PortalModel < ItemModel

    # @return [Integer] The ID of the destination room.
    attr_reader :to_room_id

    # @return [Integer] 
    attr_reader :charges

    # @return [Boolean] Whether or not the portal has a door.
    attr_reader :door

    # @return [Integer, nil] The ID of the key for this door, or nil if it has none.
    attr_reader :key_id
    
    # @return [Boolean]
    attr_reader :closed

    # @return [Boolean]
    attr_reader :locked

    # @return [Boolean]
    attr_reader :pickproof

    # @return [Boolean]
    attr_reader :passproof

    # @return [Integer] How long the portal door state takes to reset.
    attr_reader :reset_timer

    # @return [Boolean]
    attr_reader :nonspatial

    # @return [Boolean] Whether or not the portal follows you.
    attr_reader :gowith


    def initialize(id, row, temporary = true)
        super(id, row, temporary)
        @to_room_id = row[:to_room_id]
        @charges = row[:charges]
        @door = row[:door]
        @key_id = row[:key_id]
        @closed = row[:closed]
        @locked = row[:locked]
        @pickproof = row[:pickproof]
        @passproof = row[:passproof]
        @reset_timer = row[:reset_timer]
        @nonspatial = row[:nonspatial]
        @gowith = row[:gowith]
    end

    def self.item_class_name
        "portal".freeze
    end

    def self.item_class
        return Portal
    end

end
