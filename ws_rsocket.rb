
# ----------------------------------
# 
# Author: tensaix2j
#
# Websocket server
# based on RFC 6455
# 
# -----------------------------------


require 'rubygems'
require 'socket'
require "base64"
require 'digest/sha1'

$MAXSIZE = 65544

$config = {
	"-port" 	=> 10000,
	"-debug"	=> 0
}



#--------
def accept_new_connection( sock )
	
	newsock = sock.accept
	@descriptors << newsock
	@clients << newsock;
	
	puts "#{newsock.to_s} connected."
	
end

#-----------
def settle_incoming_msg( sock )

	puts "<settle_incoming_msg>" if $config["-debug"].to_i > 3
	
	begin
		if sock.eof? 
			puts "#{sock.to_s} closed."
			sock.close
			@descriptors.delete(sock)
			@clients.delete( sock )
			@wsclients.delete( sock )

		else

			raw_msg = sock.read_nonblock($MAXSIZE)
			process_msg( raw_msg  , sock)

		end
	
	rescue Exception => e  
		puts "ERROR: #{ e.to_s } #{e.backtrace() }"
	end

	puts "<settle_incoming_msg> Done." if $config["-debug"].to_i > 3
	
end







#----------------
def process_msg( raw_msg , sock ) 
	
	puts "<process_msg>: " if $config["-debug"].to_i > 2
	puts "raw_msg: #{raw_msg} " if $config["-debug"].to_i > 4
	
	
	if raw_msg.length > 0

		# Websocket handshake
		if raw_msg[0...10][/GET/]

			msg_arr = raw_msg.gsub("\r\n","\n").split("\n")
			
			ws_key = nil
			msg_arr.each { |line|

				k = line.split(" ")
				if ( k[0][/Sec-WebSocket-Key:/] ) 
					ws_key = k[1]
				end
			}
			if ws_key

				puts "WS open request, responding back."
				
				# Websocket open handshake
				guid 	= "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
				websocket_accept_key = Base64.encode64( Digest::SHA1.digest( "#{ws_key}#{guid}" ) )
				sock.write "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{websocket_accept_key}\r\n"
			
				@wsclients << sock
			end

		else
			
			# Websocket
			if @wsclients.index( sock ) != nil

				msg = ''
				extract_msg( raw_msg , msg )
				ws_onmessage( sock , msg )


			# ordinary TCPIP socket
			else
				raw_onmessage( sock , raw_msg )
			end		
						
		end

		
	end
	
	puts "<process_msg>: Done\n" if $config["-debug"].to_i > 2
end



#--------------------------
def ws_onmessage( ws , msg )

	puts "<ws_onmessage>: #{ws}" if $config["-debug"].to_i > 2
	puts "Data :#{msg}" if $config["-debug"].to_i > 3

	if msg[/topic_sample/] 
		

	end

	puts "<ws_onmessage>: Done.\n" if $config["-debug"].to_i > 2
	
	
end


#-------------------
def raw_onmessage( sock , data ) 

	puts "<raw_onmessage>: #{sock}" if $config["-debug"].to_i > 2
	puts "Data :#{data}" if $config["-debug"].to_i > 3

	# Don't dispatch immediately
	@buffer = '' if @buffer == nil
	@buffer.concat(data.to_s)

	if data && data.index("\n")
		
		@buffer.gsub("\r","").gsub("\n","")
		raw_dispatch_msg( sock, @buffer )
		@buffer.replace("")
	end

	puts "<raw_onmessage> Done.\n" if $config["-debug"].to_i > 2
	
end

#-------------
def raw_dispatch_msg( sock , msg ) 

	if msg[/topic_sample/] 
		
	end
end



#-------------
def extract_msg( raw_msg , msg ) 

	fin    		=   ( raw_msg[0].ord >> 7 ) & 0x01
	rsv1   		=   ( raw_msg[0].ord >> 6 ) & 0x01
	rsv2   		=   ( raw_msg[0].ord >> 5 ) & 0x01
	rsv3   		=   ( raw_msg[0].ord >> 4 ) & 0x01			 
	opcode 		=     raw_msg[0].ord  & 0x0f
	maskflag   	=   ( raw_msg[1].ord >> 7 ) & 0x01
	len    		=     raw_msg[1].ord & 0x7f
	offset 		=   2

	if len == 127 

		offset += 8
		len =  (raw_msg[2].ord << 56) + ( raw_msg[3].ord << 48) \
			 + (raw_msg[4].ord << 40) + ( raw_msg[5].ord << 32) \
			 + (raw_msg[6].ord << 24) + ( raw_msg[7].ord << 16) \
			 + (raw_msg[8].ord << 8)  + ( raw_msg[9].ord )	

	elsif len == 126

		offset += 2
		len = ( raw_msg[2].ord << 8 ) + raw_msg[3].ord
	end

	mask = []
	(0...4).each { |i|
		mask[i] = raw_msg[offset + i] 
	}

	offset += 4
	if opcode == 0x01 
		(0...len).each { |i|
			msg << ( raw_msg[offset + i].ord ^ mask[i % 4] ).chr
		}
	end

end




#----------------------------------------
def send_ws_frame( ws , application_data )

	if application_data.length <= 1024 
		send_raw_ws_frame( ws, application_data , 1 , 1 )
	else

		(0...application_data.length).step(1024).each { |i|

			is_frame_head = 1 if i == 0
			is_frame_last = 1 if i + 1024 >= application_data.length 
			send_raw_ws_frame( ws, application_data[i...i+1024] , is_frame_head, is_frame_last )
		}
	end
end



#------------
def send_raw_ws_frame( ws , application_data, is_frame_head , is_frame_last )

	if application_data.length > 0 

		frame = (( is_frame_head.to_i & 0x01 ) | ( is_frame_last.to_i << 7 )).chr
		length = application_data.length


		if length <= 125

		  frame << length

		elsif length < 65536 # write 2 byte length

			frame << "\x7e"
			frame << [length].pack('n')

		else # write 8 byte length

			frame << "\x7f"
			frame << [length >> 32, length & 0xFFFFFFFF].pack("NN")
		end

		frame << application_data

		begin

			ws.write(frame)

		rescue Exception => ex

			puts "<send_ws_frame> Error sending to browser #{ ws }. #{ ex.to_s }.\n#{ frame.unpack("H*") }\n\n#{ ex.backtrace() }"

		end
	end	
end



#------------
def main( argv )

	$config = $config.merge( Hash[*argv] )
	
	port =  $config["-port"] 
	

	@descriptors = Array::new
	@wsclients = Array::new

	
	@serverSocket = TCPServer.new("", port)
	@serverSocket.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
	@descriptors << @serverSocket
	@clients = []
	printf "Server started on port %d\n", port
	
	while (1)
		
		res = select( @descriptors, nil ,nil ,nil )
		if res != nil
			res[0].each do
				|sock|
				if sock == @serverSocket 
					accept_new_connection( sock )
				else
					settle_incoming_msg( sock )
				end
			end
		end
	end
end

main ARGV



