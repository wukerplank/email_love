#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'lockfile'
require 'mail'
require 'gmail'
require 'net/pop'

require './lib/message_handler.rb'

begin
  Lockfile.new('running.lock', retries: 0) do
    begin
      config = YAML.load_file("./config/config.yml")
      users  = YAML.load_file("./config/users.yml")

      handler = MessageHandler.new(users)

      Gmail.new(config['username'], config['password']) do |gmail|
        handler.gmail = gmail

        gmail.inbox.emails(:unread).each do |email|
          begin
            handler.handle_message(email)
          rescue Exception => e
            puts e
            puts e.backtrace
          end
          puts "-" * 80
        end
      end
    rescue Exception => e
      puts e
    end
  end
rescue Lockfile::MaxTriesLockError => e
  # An instance of this script is already running, so do nothing
end
