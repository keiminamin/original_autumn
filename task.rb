require './models'
require 'line/bot'
require 'dotenv'
Dotenv.load
def client

  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]

  }
  end
