require_relative 'command.rb'

class CommandSay < Command

    def initialize
        super(
            name: "say",
            keywords: ["say", "'"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output 'Say what?'
            return false
        else
            message = input[/#{cmd} (.*)/, 1]

            data = { text: message }
            Game.instance.fire_event( actor, :event_communicate, data )
            message = data[:text]

            actor.room.occupants.each_output "{y0<N> say0<,s> '#{message}'{x", [actor]
            return true
        end
    end

end

class CommandScore < Command

    def initialize
        super(
            name: "score",
            keywords: ["score"]
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output actor.score
        return true
    end
end

class CommandSell < Command

    def initialize
        super(
            name: "sell",
            keywords: ["sell"],
            lag: 0,
            position: :resting
        )
    end

    # buy and sell need a default quantity of '1', since otherwise the targeting system would buy the entire stock of a shop at once

    def attempt( actor, cmd, args, input )
        if ( shopkeeper = actor.target({ visible_to: actor, list: actor.room.occupants, affect: "shopkeeper", not: actor }).first )
            actor.target({ visible_to: actor, list: actor.inventory.items }.merge( args.first.to_s.to_query( 1 ) ) ).each do |sale|

                # we are selling, the shopkeeper is buying, so wer use the shopkeeper 'buy price'

                if shopkeeper.spend( shopkeeper.buy_price( sale ) )
                    sale.move(shopkeeper.inventory)
                    actor.earn( shopkeeper.buy_price( sale ) )
                    actor.output( "You sell #{sale} for #{ shopkeeper.buy_price( sale ).to_worth }." )
                else
                    shopkeeper.do_command "say I'm afraid I don't have enough wealth to buy #{ sale }!"
                end
            end
        else
            actor.output "You can't do that here."
            return false
        end
    end

end

class CommandSkills < Command

    def initialize
        super(
            name: "skills",
            keywords: ["skills"]
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output %Q(Skills:
#{ actor.skills.map{ |skill| actor.knows( skill ) ? "{G#{ skill }{x" : "{y#{skill}{x" }.each_slice(2).map{ |row| "#{row[0].to_s.rpad(18)}       #{row[1].to_s.rpad(18)} " }.join("\n")}

Weapons:
#{ actor.proficiencies.map(&:name).join(", ") })
        return true
    end

end

class CommandSpells < Command

    def initialize
        super(
            name: "spells",
            keywords: ["spells"]
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output %Q(Spells:
#{ actor.spells.map{ |spell| actor.knows( spell ) ? "{C#{ spell }{x" : "{y#{spell}{x" }.each_slice(2).map{ |row| "#{row[0].to_s.rpad(18)}       #{row[1].to_s.rpad(18)} " }.join("\n")})
        return true
    end

end

class CommandSleep < Command

    def initialize
        super(
            name: "sleep",
            keywords: ["sleep"],
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        if actor.position == :sleeping
            actor.output "You are already asleep."
            return false
        elsif actor.position == :resting || actor.position == :standing
            actor.output "You go to sleep."
            (actor.room.occupants - [actor]).each_output "0<N> lies down and goes to sleep.", [actor]
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
        actor.position = :sleeping.to_position
        return true
    end
end

class CommandSocial < Command

    def initialize
        super(
            name: "social",
            keywords: [],
            priority: 0
        )
        @socials = Game.instance.social_data
        @keywords.decrement_use_count
        @keywords = Keywords.keywords_for_array(@socials.map { |id, row| row[:keyword] }.concat(["social"]))
    end

    def attempt( actor, cmd, args, input )
        # get the social row for the keyword used
        social = @socials.values.find{ |social| social[:keyword].fuzzy_match( cmd ) }

        if !social # no matching social - must have used "social" keyword. show social list!
            actor.output("SOCIALS\n\n#{@socials.map { |id, row| row[:keyword].capitalize_first }.join("\n").to_columns(15, 5)}")
            return
        end

        # default to no target values
        p1 = social[:p1_no_arg]
        p2 = nil
        p3 = nil
        p3 = social[:p3_no_arg] if social[:p3_no_arg].to_s.length > 0
        target = nil

        if args.length > 0 # trying to target something?
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
            if target
                if target == actor # target self
                    p1 = social[:p1_target_self] if social[:p1_target_self].to_s.length > 0
                    p3 = social[:p3_target_self] if social[:p3_target_self].to_s.length > 0
                else # target found
                    p1 = social[:p1_target_found] if social[:p1_target_found].to_s.length > 0
                    p2 = social[:p2_target_found] if social[:p2_target_found].to_s.length > 0
                    p3 = social[:p3_target_found] if social[:p3_target_found].to_s.length > 0
                end
            else # target not found
                p1 = social[:p1_target_not_found] if social[:p1_target_not_found].to_s.length > 0
            end
        end

        actor.output(p1.capitalize_first, [actor, target])
        target.output(p2.capitalize_first, [actor, target]) if p2 && target
        (actor.room.occupants - [actor, target]).each_output(p3.capitalize_first, [actor, target]) if p3
    end

    # override for overwrite_attributes in order to keep all social keywords from database
    def overwrite_attributes(new_attr_hash)
        @id = new_attr_hash[:id].to_i
        @priority = new_attr_hash[:priority].to_i
        @lag = new_attr_hash[:lag].to_f
        @name = new_attr_hash[:name].to_s
        @usable_in_combat = new_attr_hash[:usable_in_combat]
        @creation_points = new_attr_hash[:creation_points]
        @position = Game.instance.positions[(new_attr_hash[:position_id] || 1)]
        @hp_cost = new_attr_hash[:hp_cost].to_i
        @mana_cost = new_attr_hash[:mana_cost].to_i
        @movement_cost = new_attr_hash[:movement_cost].to_i
        data_string = new_attr_hash[:data]
        if data_string && data_string.length > 0
            @data = JSON.parse(data_string, symbolize_names: true)
        end
    end

end

class CommandStand < Command

    def initialize
        super(
            name: "stand",
            keywords: ["stand"],
            priority: 200
        )
    end

    def attempt( actor, cmd, args, input )
        case actor.position.symbol
        when :sleeping
            actor.output "You wake and stand up."
            (actor.room.occupants - [actor]).each_output "0<N> wakes and stands up.", [actor]
            actor.position = :standing.to_position
            actor.look_room
            return true
        when :resting
            actor.output "You stand up."
            (actor.room.occupants - [actor]).each_output "0<N> stands up.", [actor]
            actor.position = :standing.to_position
            return true
        when :standing
            actor.output "You are already standing."
            return false
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
    end
end
