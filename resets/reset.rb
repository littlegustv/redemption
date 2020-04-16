# Base reset class to contain basic variables and logic.
# This class contains essentially everything except actual
# repop logic and variables, eg: mobile id, room id, etc
class Reset

    attr_reader :pop_time

    def initialize(timer, chance)
        @timer = 5
        @chance = chance
        @pop_time = 0
    end

    # called when the time for reset has come to determine if the reset was successful.
    # if it wasn't, it reactivates itself!
    def success?
        if @pop_time != 0 && @chance != 100 && dice(1, 100) > @chance
            self.activate
            return false
        end
        return true
    end

    # handle actual repop logic. overridden by subclasses for actual gameobjects
    def pop
        # Reset.pop never called: only overrides!
        log("{rBase reset #pop called - should only ever call overrides!{x")
    end

    # call to queue the reset as active
    def activate(instant = false)
        if instant
            @pop_time = 0
        else
            @pop_time = Time.now.to_i + @timer
        end
        Game.instance.activate_reset(self)
    end

end
