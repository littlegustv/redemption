require_relative '../command'

class Spell < Command

	@@syllables = {
		"ar" => "abra",
		"au" => "kada",
		"bless" => "fido",
		"blind" => "nose",
		"bur" => "mosa",
		"cu" => "judi",
		"de" => "oculo",
		"en" => "unso",
		"light" => "dies",
		"lo" => "hi",
		"mor" => "zak",
		"move" => "sido",
		"ness" => "lacri",
		"ning" => "illa",
		"per" => "duda",
		"ra" => "gru",
		"fresh" => "ima",
		"re" => "candus",
		"son" => "sabru",
		"tect" => "infra",
		"tri" => "cula",
		"ven" => "nofo",
		"a" => "a",
		"b" => "b",
		"c" => "q",
		"d" => "e",
		"e" => "z",
		"f" => "y",
		"g" => "o",
		"h" => "p",
		"i" => "u",
		"j" => "y",
		"k" => "t",
		"l" => "r",
		"m" => "w",
		"n" => "i",
		"o" => "a",
		"p" => "s",
		"q" => "d",
		"r" => "f",
		"s" => "g",
		"t" => "h",
		"u" => "j",
		"v" => "z",
		"w" => "x",
		"x" => "n",
		"y" => "l",
		"z" => "k",
	}

	def translate( name )
		translation = name
		@@syllables.each{ |key, value| translation = translation.gsub(key, value.upcase) }
		translation.downcase
	end

	def cast( actor, spell, args )
		if not actor.use_mana( @mana_cost )
			actor.output "You don't have enough mana"
		else
			actor.output "You utter the words '#{translate( @name )}'"
			actor.broadcast "%s utters the words '#{translate( @name )}'", actor.target({ not: actor, room: actor.room, type: ["Mobile", "Player"] }), [actor]

			actor.cast( self, args )
            actor.lag += @lag
		end
	end

    def execute( actor, cmd, args )
        if actor.position < @position # Check position
            case actor.position
            when Position::SLEEP
                actor.output "In your dreams, or what?"
            when Position::REST
                actor.output "Nah... You feel too relaxed..."
            else
                actor.output "You can't quite get comfortable enough."
            end
            return false
        end
        if actor.attacking && !@usable_in_combat
            actor.output "No way! You're still fighting!"
            return false
        end
        level = actor.casting_level
        success = attempt( actor, cmd, args, level )
        return success
    end

end
