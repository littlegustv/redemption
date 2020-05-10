module Constants

    module Tips
        TOPTIPS = [
		"Strength determines how much weight you can carry, increases your chance of hitting slightly, and gives a large boost to your damage.",
		"Dexterity determines how many items you can carry, increases your armor class, and the success of many combat skills.",
		"Constitution determines how many hit points you get when you level up, and reduces the damage you take from magic.",
		"Intelligence determines how fast your skills improve, and the success of many spells.",
		"Wisdom determines how many practices you get when you level up, and the damage of many spells.",
		"Armor class shields you from physical attacks by causing them to miss.",
		"Raising your hit roll is one way to increase your chance of hitting. Bless, enchantments and items raise it.",
		"Damage roll increases the damage you do with your physical attacks, but not on a one to one ratio.",
		"Saving throws lower the success of enemy magic. The lower your saving throws, the better.",
		"You can store excess money on a bank note. The bank is located on wary way in the north part of midgaard. Another is in Southern Shandalar. Be careful, other players can use the bank note if they get it.",
		"You can type help <topic> to get information about all game commands and many other topics.",
		"You must use the single quotes (') to enclose a multi-word string that is to be taken as a single parameter. For example, the names of multi-word spells (cast 'acid blast' lion)",
		"Additional character information becomes available as you level up to level 25.",
		"You can wear a second floating object starting at level 25, as an orbital.",
		"The healer located north of recall will help you by curing negative status spells or your wounds if you wait long enough and are of low enough level.",
		"After level 5, you must use the Temple of Concentration in Midgaard, or Selinas Coven in Shandalar in order to practice and train.",
		"The consider command can show you how tough a mob is relative to yourself. Use it to avoid battles you can't win.",
		"Type areas to see a list of all areas available and what areas are suitable for your level.",
		"You are safe from other players for 3 minutes after you die, but mobs can still attack you.",
		"Keep an extra set of leveling equipment which boosts your constitution, intelligence and wisdom and wear it just before you gain a level up to maximize your character's potential.",
		"The animal growth spell is a great easy way to boost your constitution before you level.",
		"Hatchlings will grow into one of the five dragon colors when they reach level 10. The color of dragon you reach is RANDOM and only determined as you reach level 10. Each color of dragon has its own special skill.",
		"All characters should probably have the dodge, parry and shield block skills to survive combat. You should also add the maximum number of attacks you can according to your class.",
		"Bash and trip accomplish similar things, however each is useful against different targets so it may be useful to have both skills.",
		"Thieves may use backstab repeatedly until their victim's are sufficiently injured. When hasted, a thief deals two backstabs instead of one.",
		"A mob under the control of a player character is called a charmie by convention, since charmies were originally obtained through the use of the charm person spell.",
		"Buy a pet in town as soon as you can, they add some firepower and can also be ordered to perform almost any action including skills they may know, or attacking for you. (help order)",
		"The bakery is the best place to buy food. You can also eat monster parts if you're desperate, but most of them are poisonous.",
		"You can find maps for most of the areas of the game on various websites. Start by looking at www.redemptionmud.com and check the links.",
		"Type a channel's name with no message to turn it on or off, including this channel.",
		"Once you reach mid or high level, you should always have sanctuary on to maximize your chances of survival.",
		"Type auto to see a list of toggles. Some of them can mean life or death, such as being immune to summon and cancellation except when needed.",
		"You can abbreviate most commands to one or two letters for convenience. Be careful to use several letters when specifying targets so you dont hit the wrong victim, such as a player.",
		"Dont spend trains on your stats such as strength; there are many items that can easily raise them to your racial maximums without using trains. Save trains for other things such as hp.",
		"Players who chose to be in the pkill system can join a clan at level 10. Contact a leader or recruiter for the clan you want to join. (help clans)",
		"Clan members have a clan hall where they get shops, a room to heal in quickly, a healer and portals to many areas. Clan halls can be invaded by enemy clans by killing the goons!",
		"Non-clanners can choose to join guilds at any time. These are similar to clans but with less options for their guild halls. (help nonclanner guild) ",
		"Make sure you know the rules and follow them. Severe penalties including deletion may result from repeated rules breaking. (help rules)",
		"Immortals sometimes run trivia contests or tournaments where there is no penalty for death. Feel free to join in when these activities occur!",
		"Once you reach level 51, you can start over at level 1 by remorting to special race or reclassing to a special class. You can do each one once for a total of 153 levels.",
		"The questmaster offers gold at lower levels, but at level 51 he also awards quest points which are used to remort/reclass or buy powerful quest equipment.",
		"Crafted items are equipment that are made by combining other items together and knowing the proper keywords. The recipes are well hidden. Many crafted items are very useful and can do things normal items cannot.",
		"You will attack automatically in combat to the best of your ability. In between combat rounds you may choose extra actions such as casting spells, or using skills like bash on your foe, or trying to flee.",
		"Wimpy is a feature that will make you try to flee automatically when your hit points go below a certain amount. Use this to prevent you from accidentally dying!",
		"Some mobs are aggressive and will attack you on sight. Be careful as it is easy to die to aggressive mobs especially if they appear in a group.",
		"You can safely level in mud school up to level 5 before exploring further. Ask other players for directions, the low level areas are usually close to town.",
		"If any immortals are on when you gain a level, they will usually give you a gift. Most gifts are pills that when eaten will power you up for a short while. Use them wisely!",
		"Humans, Elves, Marids, Dwarves, Giants and Hatchlings start on Terra. Trolls, Slivers, Gargoyles, Kirre start on Dominia.",
        "There are three ways to change continents. Pay the warp ability south and west of recall, take the land bridge, or use the portal/nexus spells.",
        "By worshipping a deity, you can collect deity points and use them for additional bonus spells. Both deity spells and clan spells use these deity points instead of mana. (help worship)",
		"Most players and some mobs have weaknesses to certain elements or weapons, be sure to take advantage of this in combat!",
		"Practice sessions are more effective when your intelligence is high, so get items (such as the painting of the warlock) that boost your intelligence when you use your practice sessions!",
		"Not all races take as long to level up. Humans are by far the quickest, while a dragon can take quite a while to level up.",
		"Some stats, such as saves and armor class, are better as negatives than positives: -10 saves is better than -5 saves.",
		"Being aggressive towards other players, if you're in the pkill system, can get you a {RKiller{M or a {YThief{M flag. These means that high level players and certain mobs will attack you.",
		"{RKiller{M and {YThief{M flags can be obtained by attacking people, stealing from people, or even sometimes just casting an area attack spell in the same room. Use care!",
		"After attacking a player or being attacked, you won't be able to quit for 3 ticks. This also occurs if you try and steal from someone, even if you're unsuccessful!",
		"Typing 'color' will turn on (or off) coloured messages. It's very helpful for differentiating between channels and such.",
        "Entering the exclamation mark, !, as a command on a new line will repeat the command. This is useful when you want to enter the same command repeatedly and quickly (such as flee).",
        ]
    end

    module Quests
        module Villain
            FIRST = [
                "One of this land's worst foes, %s, has escaped from the dungeon!",
                "A villain by the name of %s has named itself an enemy of our town.",
                "There has been an attempt on my life by %s!",
                "The local people are being terrorized by %s.",
            ]
            SECOND = [
                "Since then, %s has murdered %d people!",
                "The local people are very scared of %s.",
                "A young girl has recently gone missing, we fear the worst.",
                "There is fear %s may try and start a rebellion.",
            ]
            THIRD = [
                "The penalty for this crime is death, and I am sending you to deliver the sentence.",
                "The town has chosen YOU to resolve this situation.",
                "Only you are strong enough to end this threat!",
                "I wish you the best of luck in slaying %s.",
            ]
        end

        module Item
            FIRST = [
                "Vile thieves have stolen %s from the royal treasury!",
                "A group of diplomats visited last week, and now %s is missing from the capital!",
                "The local ruler's bumbling aid seems to have misplaced %s!",
                "A travelling caravan was robbed of %s out in the wilds!"
            ]
        end
    end

    module Time
        DAYS = [ "the Moon", "the Bull", "Deception", "Thunder", "Freedom","the Great Gods", "the Sun" ]
        MONTHS = [
            "Winter", "the Winter Wolf", "the Frost Giant", "the Old Forces",
            "the Grand Struggle", "the Spring", "Nature", "Futility", "the Dragon",
            "the Sun", "the Heat", "the Battle", "the Dark Shades", "the Shadows",
            "the Long Shadows", "the Ancient Darkness", "the Great Evil"
        ]
        SUNRISE = 6
        SUNSET = 18
    end

    module Directions
        INVERSE = {
            north: :south,
            south: :north,
            up: :down,
            down: :up,
            east: :west,
            west: :east
        }
    end

    module Damage
        DAMROLL_MODIFIER = 0.6
    end

    # full stock for shopkeepers
    SHOP_FULL_STOCK = 5
    # % markup on buy/sell transactions
    SHOP_MARKUP = 0.05

    module Interval
        FPS = 30
        ROUND = FPS * 3	    	# let's try 3 seconds
        TICK = FPS * 60			# 1 minute
        AUTOSAVE = FPS * 60     # 1 minute
        RESETS_PER_FRAME = 10000 / FPS
    end

    DAMAGE_DECORATORS = {
		0 => ["miss", "misses", " clumsy", "."],
		4 => ["bruise", "bruises", " clumsy", "."],
		8 => ["scrape", "scrapes", " wobbly", "."],
		12 => ["scratch", "scratches", " wobbly", "."],
		16 => ["lightly wound", "lightly wounds", " amateur", "."],
		20 => ["injure", "injures", " amateur", "."],
		24 => ["harm", "harms", " competent", ", creating a bruise"],
		28 => ["thrash", "thrashes", " competent", ", leaving marks!"],
		32 => ["maul", "mauls", " skillful", "!"],
		36 => ["maim", "maims", " skillful", "!"],
		40 => ["decimate", "decimates", " cunning", ", the wound bleeds!"],
		44 => ["devastate", "devastates", " cunning", ", hitting organs!"],
		48 => ["mutilate", "mutilates", " calculated", ", shredding flesh!"],
		52 => ["cripple", "cripples", " calculated", ", leaving GAPING holes!"],
		60 => ["DISEMBOWEL", "DISEMBOWELS", " calm", ", guts spill out!"],
		68 => ["DISMEMBER", "DISMEMBERS", " calm", ", blood sprays forth!"],
		76 => ["ANNIHILATE!", "ANNIHILATES!", " furious", ", revealing bones!"],
		84 => ["OBLITERATE!", "OBLITERATES!", " furious", ", rending organs!"],
		92 => ["DESTROY!!", "DESTROYS!!", " frenzied", ", severing arteries!"],
		100 => ["DESTROY!!", "DESTROYS!!", " frenzied", ", shattering bones!"],
		110 => ["MASSACRE!!", "MASSACRES!!", " barbaric", ", gore splatters everywhere!"],
		120 => ["!ERADICATE!", "!ERADICATES!", " fierce", ", leaving little remaining!"],
		130 => ["!DECAPITATE!", "!DECAPITATES!", " deadly", ", scrambling some brains"],
		149 => ["{r!!SHATTER!!{x", "{r!!SHATTERS!!{x", " legendary", " into tiny pieces"],
		150 => ["do {RUNSPEAKABLE{x things to", "does {RUNSPEAKABLE{x things to", " ultimate", "!"]
    }

    MAGIC_DAMAGE_DECORATORS = {
        0 => ["miss", "misses", "", "."],
        4 => ["scratch", "scratches", "", "."],
        8 => ["graze", "grazes", "", " slightly."],
        12 => ["hit", "hits", "", " squarely."],
        16 => ["injure", "injures", "", "."],
        20 => ["wound", "wounds", "", " badly."],
        25 => ["maul", "mauls", "", "!"],
        30 => ["maim", "maims", "", "!"],
        35 => ["decimate", "decimates", "", "!"],
        40 => ["devastate", "devastates", "", ", leaving a hole!"],
        45 => ["MUTILATE", "MUTILATES", "", " severely!"],
        50 => ["DISEMBOWEL", "DISEMBOWELS", "", ", causing bleeding!"],
        55 => ["DISMEMBER", "DISMEMBERS", "", ", blood flows!"],
        60 => ["MANGLE", "MANGLES", "", ", bringing screams!"],
        65 => ["** DEMOLISH **", "** DEMOLISHES **", "", " with skill!"],
        70 => ["*** CRIPPLE ***", "*** CRIPPLES ***", "", " for life!"],
        75 => ["*= WRECK =*", "*= WRECKS =*", "", "!"],
        80 => ["=*= BLAST =*=", "=*= BLASTS =*=", "", ", charring flesh!"],
        90 => ["=== ANNIHILATE ===", "=== ANNIHILATES ===", "", "!"],
        100 => ["=== OBLITERATE ===", "=== OBLITERATES ===", "", "!"],
        110 => [">> DESTROY <<", ">> DESTROYS <<", "", " almost completely!"],
        120 => [">>> MASSACRE <<<", ">>> MASSACRES <<<", "", " like a lamb at slaughter!"],
        130 => ["<! VAPORIZE !>", "<! VAPORIZES !>", "", " completely!"],
        149 => ["<<< ERADICATE >>>", "<<< ERADICATES >>>", "", "!"],
        150 => ["do {RUNSPEAKABLE{x things to", "does {RUNSPEAKABLE{x things to", "", "!!"],
    }

    ALIGNMENT_DESCRIPTIONS = {
        700 => "0<n> has a pure and good aura.",
        350 => "0<n> is of excellent moral character.",
        100 => "0<n> is often kind and thoughtful.",
        -100 => "0<n> doesn't have a firm moral commitment.",
        -350 => "0<n> lies to their friends.",
        -700 => "0<n> is a black-hearted murderer.",
        -1000 => "0<n> is the embodiment of pure evil.",
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
        CommandTime,
        CommandWeather,
        CommandOpen,
        CommandClose,
        CommandLock,
        CommandUnlock,
        CommandEnter,
        CommandPry,
        CommandProfile,
        CommandLearn,
        CommandQuest,
        CommandEmote,
        CommandSocial,
        CommandEat,
        CommandQuaff,
        CommandPeer,
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
        SkillSteal,
        SkillShadow,
        SkillEnvenom,
        SkillHide,
        SkillPickLock,
        SkillAppraise,
        SkillLair,
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
        SpellEnchantArmor,
        SpellEnergyDrain,
        SpellFireRune,
        SpellGate,
        SpellHurricane,
        SpellHaste,
        SpellGiantStrength,
        SpellAnimalGrowth,
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
        SpellFly,
        SpellBlindness,
        SpellSleep,
        SpellGrandeur,
        SpellMinimation,
        SpellFrenzy,
        SpellTaunt,
        SpellStun,
        SpellBless,
        SpellHolyWord,
        SpellDemonFire,
        SpellScramble,
        SpellInfravision,
        SpellContinualLight,
        SpellCharmPerson,
        SpellCalm,
        SpellHeatMetal,
        SpellRayOfTruth,
        SpellPassDoor,
        SpellCreateFood,
        SpellCreateRose,
        SpellCreateSpring,
        SpellFloatingDisc,
        SpellDarkness,
        SpellKarma,
        SpellPortal,
        SpellNexus,
    ]

    AFFECT_CLASSES = [
        AffectAggressive,
        AffectAlarmRune,
        AffectAnimalGrowth,
        AffectArmor,
        AffectBarkSkin,
        AffectBerserk,
        AffectBladeRune,
        AffectBless,
        AffectBlind,
        AffectBlur,
        AffectBurstRune,
        AffectCalm,
        AffectCharm,
        AffectChilled,
        AffectCloakOfMind,
        AffectCloudkill,
        AffectCorroded,
        AffectCorrosiveWeapon,
        AffectCurse,
        AffectDark,
        AffectDarkness,
        AffectDarkvision,
        AffectDeathRune,
        AffectDetectInvisibility,
        AffectEnchantWeapon,
        AffectEnchantArmor,
        AffectEssence,
        AffectFireBlind,
        AffectFlamingWeapon,
        AffectFloodingWeapon,
        AffectFlooded,
        AffectFly,
        AffectFollow,
        AffectFrenzy,
        AffectFrostWeapon,
        AffectGiantStrength,
        AffectGlowing,
        AffectGrandeur,
        AffectGuard,
        AffectHaste,
        AffectHatchling,
        AffectHide,
        AffectIgnoreWounds,
        AffectImmunity,
        AffectIndoors,
        AffectInfravision,
        AffectInvisibility,
        AffectKarma,
        AffectKiller,
        AffectLair,
        AffectLivingStone,
        AffectMinimation,
        AffectMirrorImage,
        AffectPassDoor,
        AffectPlague,
        AffectPoisoned,
        AffectPoisonWeapon,
        AffectPortal,
        AffectProtectionEvil,
        AffectProtectionGood,
        AffectProtectionNeutral,
        AffectQuestItem,
        AffectQuestMaster,
        AffectQuestVillain,
        AffectRegeneration,
        AffectResistance,
        AffectScramble,
        AffectShackle,
        AffectShackleRune,
        AffectShield,
        AffectShocked,
        AffectShockingWeapon,
        AffectShopkeeper,
        AffectSleep,
        AffectSlow,
        AffectSneak,
        AffectStoneSkin,
        AffectStun,
        AffectTaunt,
        AffectVulnerable,
        AffectWeaken,
        AffectZeal,
    ]

    ITEM_MODEL_CLASSES = [
        ConsumableModel,
        PillModel,
        PotionModel,
        ContainerModel,
        ItemModel,
        WeaponModel,
    ]

    module Gender

        DEFAULT = {
            :id => 1,
            :name => "neutral",
            :personal_objective => "it",
            :personal_subjective => "it",
            :possessive => "its",
            :reflexive => "itself",
        }

    end

    module OutputFormat

        REPLACE_HASH = {
            "n" => :resolve_name,
            "s" => :resolve_short_description,
            "l" => :resolve_long_description,
            "o" => :resolve_personal_objective_pronoun,
            "u" => :resolve_personal_subjective_pronoun,
            "p" => :resolve_possessive_pronoun,
            "r" => :resolve_reflexive_pronoun,
        }

    end

end
