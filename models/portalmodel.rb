class PortalModel < ItemModel

    attr_reader :to_room_id
    attr_reader :charges
    attr_reader :door
    attr_reader :key_id
    attr_reader :closed
    attr_reader :locked
    attr_reader :pickproof
    attr_reader :passproof
    attr_reader :reset_timer
    attr_reader :nonspatial
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
