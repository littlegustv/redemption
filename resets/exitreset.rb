class ExitReset < Reset

    attr_accessor :exit

    def initialize( exit, closed, locked, timer )
        super(timer)
        @exit = exit
        @closed = closed
        @locked = locked
    end

    ## Try to reset.
    def pop
        @exit.closed = @closed
        @exit.locked = @locked
    end


end
