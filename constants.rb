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

    # chance (out of ten) of an elemental flag effect
    
    ELEMENTAL_CHANCE = 3

    FPS = 30
    ROUND = FPS * 1		    # 1 second
    TICK = FPS * 60			# 1 minute
    RESET = FPS * 3 * 60    # 3 minutes
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

    MAGIC_DAMAGE_DECORATORS = {
        0 => ["misses", "", "."],
        4 => ["scratches", "", "."],
        8 => ["grazes"," slightly","."],
        12 => ["hits", " squarely", "."],
        16 => ["injures", "", "."],
        20 => ["wounds", " badly", "."],
        25 => ["mauls", "", "!"],
        30 => ["maims", "", "!"],
        35 => ["decimates", "", "!"],
        40 => ["devastates", ", leaving a hole", "!"],
        45 => ["MUTILATES", " severely", "!"],
        50 => ["DISEMBOWELS", ", causing bleeding", "!"],
        55 => ["DISMEMBERS", ", blood flows", "!"],
        60 => ["MANGLES", ", bringing screams", "!"],
        65 => ["** DEMOLISHES **", " with skill", "!"],
        70 => ["*** CRIPPLES ***", " for life", "!"],
        75 => ["*= WRECKS =*", "", "!"],
        80 => ["=*= BLASTS =*=", ", charring flesh", "!"],
        90 => ["=== ANNIHILATES ===", "", "!"],
        100 => ["=== OBLITERATES ===", "", "!"],
        110 => [">> DESTROYS <<", " almost completely", "!"],
        120 => [">>> MASSACRES <<<", " like a lamb at slaughter", "!"],
        130 => ["<! VAPORIZES !>", " completely", "!"],
        149 => ["<<< ERADICATES >>>", "", "!"],
        150 => ["does {RUNSPEAKABLE{x things to", "", "!!"],
    }

    ELEMENTAL_EFFECTS = {
        "shocking" => [ "You are shocked by %s.", "%s is struck by lightning from %s." ],
        "flooding" => [ "You are smothered in water from %s.", "%s is smothered in water from %s." ],
        "flaming" => [ "%s sears your flesh.", "%s is burned by %s." ],
        "frost" => [ "The cold touch of %s surrounds you with ice.", "%s is frozen by %s." ],
        "corrosive" => [ "Your flesh is dissolved by %s.", "%s's flesh is dissolved by %s." ],
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
