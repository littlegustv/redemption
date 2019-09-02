require 'socket'
require_relative 'constants'
require_relative 'util'
require_relative 'commands/commands'
require_relative 'game'
require_relative 'gameobject'
require_relative 'area'
require_relative 'room'
require_relative 'mobile'
require_relative 'item'
require_relative 'player'
require_relative 'affects/affects'
require_relative 'commands/spells/spells'
require_relative 'commands/skills/skills'

require_relative 'classes/classes'

game = Game.new( ARGV[0], ARGV[1] || 4000 )
