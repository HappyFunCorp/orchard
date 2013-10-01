module Orchard
  module CLI
    class Hipchat < Thor
      desc "rooms", "Show all hipchat rooms"
      def rooms
        client.rooms.sort do
          |b,a| a['last_active'].to_i <=> b['last_active'].to_i
        end.each do |r|
          printf "%6s %-35s %10s %s\n", r['room_id'], r['name'], r['last_active'], r['topic']
        end
      end

      desc "room ROOM", "Show room info"
      def room( room )
        room_info = client.room_info( room )
        puts "Name        : #{room_info['name']}"
        puts "ID          : #{room_info['room_id']}"
        puts "Topic       : #{room_info['topic']}"
        puts "Last active : #{room_info['last_active']}"
        puts "Participants:"
        room_info['participants'].each do |p|
          puts p['name']
        end
      end

      desc "users", "Show all users"
      def users
        client.users.sort do
          |b,a| a['last_active'].to_i <=> b['last_active'].to_i
        end.each do |u|
          printf "%6s %-25s %-15s %-25s %-17s %-19s %s\n", u['user_id'], u['name'], u['mention_name'], u['email'], u['last_active'], u['timezone'], u['title']
        end
      end

      desc "create ROOM", "Create a hipchat room"
      def create( room )
        puts "Creating room: #{room}"

        client.create_room( room, "Let's talk about #{room}!" )

        rooms
      end

      desc "topic ROOM TOPIC", "Set a topic of a hipchat room"
      def topic( room, topic )
        client.set_topic room, topic
      end

      desc "message ROOM MESSAGE", "Send a room a message"
      def message( room, message )
        client.post_message room, message
      end

      no_commands do
        def client
          @client ||= Orchard::Client.hipchat_client
        end
      end
    end
  end
end