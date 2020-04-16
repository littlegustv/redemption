require_relative 'command.rb'

class CommandHelp < Command

    def initialize
        super(
            name: "help",
            keywords: ["help"],
        )
    end

    def attempt( actor, cmd, args, input )
        if args.count == 0
            args.push("summary")
        end
        matches = []
        Game.instance.help_data.each do |id, help|
            valid_help = true
            args.each do |arg|
                if !help[:keywords].any? { |keyword| keyword.fuzzy_match( arg ) }
                    valid_help = false
                    break
                end
            end
            if valid_help
                matches.push help
            end
        end

        help_out = matches.map{ |row| "#{ row[:keywords].join(" ") }\n\n#{ row[:text] }" }.join("\n\n#{"=" * 80}\n\n")

        actor.output(help_out)
        return true
    end
end
