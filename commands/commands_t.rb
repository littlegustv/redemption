require_relative 'command.rb'

class CommandTime < Command

    def initialize
        super(
            name: "time",
            keywords: ["time"],
            priority: 100
        )
    end

    def attempt( actor, cmd, args, input )
        output = ""

        hour, day, year = Game.instance.time

        output += "It is {c#{ hour % 12 == 0 ? 12 : ( hour % 12 ) }{x o'clock #{ hour % 24 > 12 ? 'p.m.' : 'a.m.' }\n"
        output += "It is the day of #{ Constants::Time::DAYS[ day % Constants::Time::DAYS.count ]}, on the #{ (1 + day % 30).ordinalize } of the month of #{ Constants::Time::MONTHS[ ( day / 30 ).to_i % Constants::Time::MONTHS.count ] }.\n"
        output += "It is the year {c#{year}{x.\n"

        actor.output output

        return true
    end

end
