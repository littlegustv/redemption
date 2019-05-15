class String
	def to_a
		[ self ]
	end

	def fuzzy_match( arg )
		self.match(/\A#{arg}.*\z/i)
	end
end

module Position
    SLEEP = 0
    REST = 1
    STAND = 2
    FIGHT = 3
end

module Constants

    FPS = 60
    ROUND = 60

    DAMAGE_DECORATORS = {
		0 => ['miss', 'misses', 'clumsy', ''],
		4 => ['bruise', 'bruises', 'clumsy', ''],
		8 => ['scrape', 'scrapes', 'wobbly', ''],
		12 => ['scratch', 'scratches', 'wobbly', ''],
		16 => ['lightly wound', 'lightly wounds', 'amateur', ''],
		20 => ['injure', 'injures', 'amateur', ''],
		24 => ['harm', 'harms', 'competent', ', creating a bruise'],
		28 => ['thrash', 'thrashes', 'competent', ', leaving marks!'],
		32 => ['maul', 'mauls', 'skillfull', '!'],
		36 => ['main', 'maims', 'skillfull', '!'],
		40 => ['decimate', 'decimates', 'cunning', ', the wound bleeds!'],
		44 => ['devastate', 'devastates', 'cunning', ', hitting organs!'],
		48 => ['mutilate', 'mutilates', 'calculated', ', shredding flesh!'],
		52 => ['cripple', 'cripples', 'calculated', ', leaving GAPING holes!'],
		60 => ['DISEMBOWEL', 'DISEMBOWELS', 'calm', ', guts spill out!'],
		68 => ['DISMEMBER', 'DISMEMBERS', 'calm', ', blood sprays forth!'],
		76 => ['ANNIHILATE!', 'ANNIHILATES!', 'furious', ', revealing bones!'],
		84 => ['OBLITERATE!', 'OBLITERATES!', 'furious', ', rending organs!'],
		92 => ['DESTROY!!', 'DESTROYS!!', 'frenzied', ', severing arteries!'],
		100 => ['DESTROY!!', 'DESTROYS!!', 'frenzied', ', shattering bones!'],
		110 => ['MASSACRE!!', 'MASSACRES!!', 'barbaric', ', gore splatters everywhere!'],
		120 => ['!ERADICATE!', '!ERADICATES!', 'fierce', ', leaving little remaining!'],
		130 => ['!DECAPITATE!', '!DECAPITATES!', 'deadly', ', scrambling some brains'],
		149 => ['!!SHATTER!!', '!!SHATTERS!!', 'legendary', ' into tiny pieces'],
		150 => ['do UNSPEAKABLE things to', 'does UNSPEAKABLE things to', 'ultimate', '!']
    }

    PARTS = [
    	"brains"
    ]

end
