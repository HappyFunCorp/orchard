module Orchard
  module Client
    class HipchatClient
      attr_accessor :api

      def initialize( api )
        @api = api
      end

      def create_room( name, topic )
        creator = user_by_name 'Will Schenk'

        ret =  api.rooms_create name, creator['user_id'], 'public', topic

        if ret["error"]
          pp ret["error"]
        end

        @rooms = nil
      end

      def rooms
        @rooms ||= api.rooms_list.parsed_response['rooms']
        raise Exceptions::HipchatAuthenticationFailure if @rooms.nil?
        @rooms
      end

      def room_name_from_xmpp_jid( name )
        rooms.select{|x| x['xmpp_jid'] == name}.first['name'] rescue nil
      end

      def room_by_name( name )
        rooms.each do |r|
          return r if r['name'] == name
        end

        puts "Room #{name} not found".red
        nil
      end

      def room_info( name )
        room = room_by_name name

        if( room )
          api.rooms_show( room['room_id'] ).parsed_response['room']
        end
      end

      def users
        @users ||= api.users_list.parsed_response['users']
      end

      def user_by_name( name )
        users.each do |u|
          return u if u['name'] == name
        end

        puts "User #{name} not found".red
      end

      def set_topic( room, topic )
        room = room_by_name room

        if room
          api.rooms_topic( room['room_id'], topic)
        end
      end

      def post_message( room, message, color = 'yellow', notify = false, type = 'text' )
        room = room_by_name room

        if room
          api.rooms_message room['room_id'], 'hfc', message, notify ? "1" : "0", color, type
        end
      end
    end
  end
end
