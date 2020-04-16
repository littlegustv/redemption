require_relative 'spell.rb'

class SpellNexus < Spell

    def initialize
        super(
            name: "nexus",
            keywords: ["nexus"],
            lag: 0.25,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if actor.can_see?(nil)
            target = actor.filter_visible_targets(Game.instance.target_global_mobiles(args.first.to_s.to_query).shuffle, 1).first
        end
        if target
            portal = Game.instance.load_item( 1956, actor.room.inventory )
            # remove auto-added affect
            portal.remove_affect("portal")
            portal.apply_affect( AffectPortal.new( target: portal, game: Game.instance, destination: target.room ) )

            actor.output "0<N> rises up before you.", [portal]
            (actor.room.occupants - [actor]).each_output "0<N> rises up from the ground.", [portal]

            portal = Game.instance.load_item( 1956, target.room.inventory )
            # remove auto-added affect
            portal.remove_affect("portal")
            portal.apply_affect( AffectPortal.new( target: portal, game: Game.instance, destination: actor.room ) )

            (target.room.occupants - [actor]).each_output "0<N> rises up from the ground.", [portal]
        else
            actor.output "You can't find anyone with that name."
        end
    end

end
