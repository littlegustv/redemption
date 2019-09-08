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

	def initialize
		super()
		@mana = 10
	end

	def translate( name )
		translation = name
		@@syllables.each{ |key, value| translation = translation.gsub(key, value.upcase) }
		translation.downcase
	end

	def execute( actor, cmd, args )
		if not actor.use_mana( @mana )
			actor.output "You don't have enough mana"		
		elsif super( actor, cmd, args )
			actor.output "You utter the words '#{translate( @name )}'"
			actor.broadcast "%s utters the words '#{translate( @name )}'", actor.target({ not: actor, room: actor.room, type: ["Mobile", "Player"] }), [actor]
		else
		end
	end

end
