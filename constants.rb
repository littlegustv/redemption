module Constants

    module Position
        SLEEP = 0
        REST = 1
        STAND = 2

        STRINGS = {
            SLEEP => "sleeping",
            REST => "resting",
            STAND => "standing"
        }
    end

    module Element
        NONE = 0
        BASH = 1
        PIERCE = 2
        SLASH = 3
        FIRE = 4
        COLD = 5
        LIGHTNING = 6
        ACID = 7
        POISON = 8
        NEGATIVE = 9
        HOLY = 10
        ENERGY = 11
        MENTAL = 12
        DISEASE = 13
        DROWNING = 14
        LIGHT = 15
        OTHER = 16
        HARM = 17
        CHARM = 18
        SOUND = 19
        RAIN = 20
        VORPAL = 21
        GEOLOGY = 22

        STRINGS = {
            NONE => "none",
            BASH => "bash",
            PIERCE => "pierce",
            SLASH => "slash",
            FIRE => "fire",
            COLD => "cold",
            LIGHTNING => "lightning",
            ACID => "acid",
            POISON => "poison",
            NEGATIVE => "negative",
            HOLY => "holy",
            ENERGY => "energy",
            MENTAL => "mental",
            DISEASE => "disease",
            DROWNING => "drowning",
            LIGHT => "light",
            OTHER => "other",
            HARM => "harm",
            CHARM => "charm",
            SOUND => "sound",
            RAIN => "rain",
            VORPAL => "vorpal"
        }
    end

    module Damage
        PHYSICAL = 0
        MAGICAL = 1

        STRINGS = {
            PHYSICAL => "physical",
            MAGICAL => "magic"
        }

        RESIST_MULTIPLIER = 0.7
        VULN_MULTIPLIER = 1.3
        PROTECTION_MULTIPLIER = 0.75
    end

    # full stock for shopkeepers
    SHOP_FULL_STOCK = 5
    # % markup on buy/sell transactions
    SHOP_MARKUP = 0.05

    # chance (out of ten) of an elemental flag effect

    ELEMENTAL_CHANCE = 3
    module Interval
        FPS = 30
        ROUND = FPS * 1	    	# 1 second
        TICK = FPS * 60			# 1 minute
        REPOP = FPS * 3 * 60    # 3 minutes
        # REPOP = FPS * 4         # fast resets for testing
        AUTOSAVE = FPS * 60     # 1 minute
    end

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
		149 => ['{r!!SHATTER!!{x', '{r!!SHATTERS!!{x', 'legendary', ' into tiny pieces'],
		150 => ['do {RUNSPEAKABLE{x things to', 'does {RUNSPEAKABLE{x things to', 'ultimate', '!']
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

    ALIGNMENT_DESCRIPTIONS = {
        700 => "%s has a pure and good aura.",
        350 => "%s is of excellent moral character.",
        100 => "%s is often kind and thoughtful.",
        -100 => "%s doesn't have a firm moral commitment.",
        -350 => "%s lies to their friends.",
        -700 => "%s is a black-hearted murderer.",
        -1000 => "%s is the embodiment of pure evil.",
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

    COLOR_CODE_REPLACEMENTS = {
        "{d" => "\033[0;30m",
        "{r" => "\033[0;31m",
        "{g" => "\033[0;32m",
        "{y" => "\033[0;33m",
        "{b" => "\033[0;34m",
        "{m" => "\033[0;35m",
        "{c" => "\033[0;36m",
        "{w" => "\033[0;37m",
        "{x" => "\033[0m",
        "{D" => "\033[1;30m",
        "{R" => "\033[1;31m",
        "{G" => "\033[1;32m",
        "{Y" => "\033[1;33m",
        "{B" => "\033[1;34m",
        "{M" => "\033[1;35m",
        "{C" => "\033[1;36m",
        "{W" => "\033[1;37m",
        "{X" => "\033[39m"
    }

    COMMAND_CLASSES = [
        CommandAffects,
        CommandBlind,
        CommandBuy,
        CommandCast,
        CommandConsider,
        CommandDrop,
        CommandEquipment,
        CommandFlee,
        CommandFollow,
        CommandGet,
        CommandGive,
        CommandGoTo,
        CommandGroup,
        CommandHelp,
        CommandInspect,
        CommandInventory,
        CommandKill,
        CommandLeave,
        CommandList,
        CommandLoadItem,
        CommandLook,
        CommandLore,
        CommandMove,
        CommandOrder,
        CommandPoison,
        CommandPut,
        CommandQuicken,
        CommandQuit,
        CommandRecall,
        CommandRemove,
        CommandRest,
        CommandSay,
        CommandScore,
        CommandSell,
        CommandSkills,
        CommandSpells,
        CommandSleep,
        CommandStand,
        CommandWake,
        CommandWear,
        CommandWhere,
        CommandWhitespace,
        CommandWho,
        CommandWorth,
        CommandYell,
    ]

    SKILL_CLASSES = [
        SkillBash,
        SkillBerserk,
        SkillDirtKick,
        SkillDisarm,
        SkillKick,
        SkillLivingStone,
        SkillPaintPower,
        SkillSneak,
        SkillTrip,
        SkillZeal,
        SkillBackstab,
        SkillPeek,
        SkillSteal
    ]

    SPELL_CLASSES = [
        SpellAcidBlast,
        SpellAlarmRune,
        SpellArmor,
        SpellBarkskin,
        SpellBladeRune,
        SpellBlastOfRot,
        SpellBlur,
        SpellBurstRune,
        SpellCancellation,
        SpellCloakOfMind,
        SpellCloudkill,
        SpellCurse,
        SpellDeathRune,
        SpellDestroyRune,
        SpellDestroyTattoo,
        SpellDetectInvisibility,
        SpellDetectMagic,
        SpellEnchantWeapon,
        SpellEnergyDrain,
        SpellFireRune,
        SpellGate,
        SpellHurricane,
        SpellIceBolt,
        SpellIgnoreWounds,
        SpellInvisibility,
        SpellKnowAlignment,
        SpellLightningBolt,
        SpellLocateObject,
        SpellManaDrain,
        SpellMassInvisibility,
        SpellMirrorImage,
        SpellPhantomForce,
        SpellPhantasmMonster,
        SpellPlague,
        SpellPoison,
        SpellProtection,
        SpellPyrotechnics,
        SpellShackleRune,
        SpellShield,
        SpellSlow,
        SpellStoneSkin,
        SpellSummon,
        SpellVentriloquate,
        SpellWeaken,
        SpellMagicMissile,
        SpellBurningHands,
        SpellShockingGrasp,
        SpellColorSpray,
        SpellRukusMagna,
        SpellFireball,
        SpellChainLightning,
        SpellFlamestrike,
        SpellCauseLight,
        SpellCauseSerious,
        SpellCauseCritical,
        SpellHarm,
        SpellEarthquake,
        SpellFarsight,
        SpellDispelMagic,
        SpellRemoveCurse,
        SpellBlink,
        SpellHypnosis,
        SpellCureLight,
        SpellRefresh,
        SpellCureBlindness,
        SpellCureSerious,
        SpellCureCritical,
        SpellTeleport,
        SpellWordOfRecall,
        SpellCurePoison,
        SpellCureDisease,
        SpellHeal,
        SpellMassHealing,
    ]

    AFFECT_CLASS_HASH = {
        "aggressive" =>             AffectAggressive,
        "alarm rune" =>             AffectAlarmRune,
        "armor" =>                  AffectArmor,
        "barkskin" =>               AffectBarkSkin,
        "berserk" =>                AffectBerserk,
        "blade rune" =>             AffectBladeRune,
        "blind" =>                  AffectBlind,
        "blur" =>                   AffectBlur,
        "burst rune" =>             AffectBurstRune,
        "charm" =>                  AffectCharm,
        "cloak of mind" =>          AffectCloakOfMind,
        "cloudkill" =>              AffectCloudkill,
        "corrosive" =>              AffectCorrosive,
        "curse" =>                  AffectCurse,
        "death rune" =>             AffectDeathRune,
        "detect invisibility" =>    AffectDetectInvisibility,
        "detect invisible" =>       AffectDetectInvisibility,
        "detect_invis" =>           AffectDetectInvisibility,
        "enchant weapon" =>         AffectEnchantWeapon,
        "fireblind" =>              AffectFireBlind,
        "flooding" =>               AffectFlooding,
        "follow" =>                 AffectFollow,
        "frost" =>                  AffectFrost,
        "guard" =>                  AffectGuard,
        "haste" =>                  AffectHaste,
        "hatchling" =>              AffectHatchling,
        "ignore wounds" =>          AffectIgnoreWounds,
        "invisibility" =>           AffectInvisibility,
        "invisible" =>              AffectInvisibility,
        "killer" =>                 AffectKiller,
        "living stone" =>           AffectLivingStone,
        "mirror image" =>           AffectMirrorImage,
        "plague" =>                 AffectPlague,
        "poison" =>                 AffectPoison,
        "protect_evil" =>           AffectProtectionEvil,
        "protect_good" =>           AffectProtectionGood,
        "protect_neutral" =>        AffectProtectionNeutral,
        "shackle" =>                AffectShackle,
        "shackle rune" =>           AffectShackleRune,
        "shield" =>                 AffectShield,
        "shocking" =>               AffectShocking,
        "shopkeeper" =>             AffectShopkeeper,
        "slow" =>                   AffectSlow,
        "sneak" =>                  AffectSneak,
        "stoneskin" =>              AffectStoneSkin,
        "stun" =>                   AffectStun,
        "vuln" =>                   AffectVuln,
        "weaken" =>                 AffectWeaken,
        "zeal" =>                   AffectZeal,
        "spec_guard" =>             AffectGuard,
    }

    module ClientState
        LOGIN = 0
        ACCOUNT = 1
        CREATION = 2
        PLAYER = 3
    end

end
