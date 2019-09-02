module Position
    SLEEP = 0
    REST = 1
    STAND = 2
    FIGHT = 3

    STRINGS = [
        "sleeping",
        "resting",
        "standing",
        "fighting"
    ]
end

module Constants

    WEAPON_ELEMENTS = [
        "pierce", "bash", "slash", "magic"
    ]

    FPS = 60
    ROUND = 60				# 60 frames, 1 second
    TICK = 60 * 60			# 60 * 60 frames, 1 minute
    RESET = 3 * 60 * 60     # 3 * 60 * 60 frames, 3 minutes
    # RESET = 3 * 10 * 60     # fast resets for testing

    DAMAGE_DECORATORS = {
		0 => ['miss', 'misses', 'clumsy', '.'],
		4 => ['bruise', 'bruises', 'clumsy', '.'],
		8 => ['scrape', 'scrapes', 'wobbly', '.'],
		12 => ['scratch', 'scratches', 'wobbly', '.'],
		16 => ['lightly wound', 'lightly wounds', 'amateur', '.'],
		20 => ['injure', 'injures', 'amateur', '.'],
		24 => ['harm', 'harms', 'competent', ', creating a bruise'],
		28 => ['thrash', 'thrashes', 'competent', ', leaving marks!'],
		32 => ['maul', 'mauls', 'skillful', '!'],
		36 => ['maim', 'maims', 'skillful', '!'],
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

    EXPERIENCE_SCALE = {
        -10 => 0,
        -9 => 1,
        -8 => 2,
        -7 => 5,
        -6 => 9,
        -5 => 11,
        -4 => 22,
        -3 => 33,
        -2 => 50,
        -1 => 66,
        0 => 83,
        1 => 99,
        2 => 120,
        3 => 141,
        4 => 162,
        5 => 180,
    }

    COLOR_CODE_REPLACEMENTS = [
        ["{{", "{~"],
        ["{d", "\033[0;30m"],
        ["{r", "\033[0;31m"],
        ["{g", "\033[0;32m"],
        ["{y", "\033[0;33m"],
        ["{b", "\033[0;34m"],
        ["{m", "\033[0;35m"],
        ["{c", "\033[0;36m"],
        ["{w", "\033[0;37m"],
        ["{x", "\033[0m"],
        ["{D", "\033[1;30m"],
        ["{R", "\033[1;31m"],
        ["{G", "\033[1;32m"],
        ["{Y", "\033[1;33m"],
        ["{B", "\033[1;34m"],
        ["{M", "\033[1;35m"],
        ["{C", "\033[1;36m"],
        ["{W", "\033[1;37m"],
        ["{X", "\033[39m"],
        ["{~", "{"]
    ]

end
