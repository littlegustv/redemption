# Base reset class to contain basic variables and logic.
# This class contains essentially everything except actual
# repop logic and variables, eg: mobile id, room id, etc
class Reset

    attr_reader :pop_time

    def initialize(timer)
        @timer = 1
        @pop_time = 0
        @active = false
    end

    # called when the time for reset has come to determine if the reset was successful.
    def success?
        # if something # possibility of event interception?
        #     self.activate
        # end
        if !@active
            return false
        end
        @active = false
        return true
    end

    # handle actual repop logic. overridden by subclasses for actual gameobjects
    def pop
        # Reset.pop never called: only overrides!
        log("{rBase reset #pop called - should only ever call overrides!{x")
    end

    # call to queue the reset as active
    def activate(instant = false)

        if @active # already active, just return
            return
        end
        @active = true
        if instant
            @pop_time = 0
        else
            @pop_time = Game.instance.frame_time + @timer
        end
        Game.instance.activate_reset(self)
    end

    def deactivate
        @active = false
    end

end
