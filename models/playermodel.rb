class PlayerModel < MobileModel

    attr_reader :creation_points
    attr_reader :account_id

    def initialize(id, row)
        super(id, row, true)
        @creation_points = row[:creation_points] || 0
        @account_id = row[:account_id] || 0

        @short_description = @name
        @long_description = "#{@name} the Master Rune Maker is here."
    end

end
