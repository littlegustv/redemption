require 'socket'
require_relative 'constants'
require_relative 'commands'
require_relative 'game'
require_relative 'gameobject'
require_relative 'area'
require_relative 'room'
require_relative 'mobile'
require_relative 'item'
require_relative 'player'

game = Game.new( ARGV[0], ARGV[1] || 4000 )
