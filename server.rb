require 'socket'
require_relative 'constants'
require_relative 'commands'
require_relative 'game'
require_relative 'gameobject'
require_relative 'room'
require_relative 'mobile'
require_relative 'player'

game = Game.new( ARGV[0] || "127.0.0.1", ARGV[1] || 2000 )