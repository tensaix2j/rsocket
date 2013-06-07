
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


#--------
def accept_new_connection( sock )
	
	newsock = sock.accept
	@descriptors << newsock
	@clients << newsock;
	
	puts "#{newsock.to_s} connected."
	
end

#-----------
def settle_incoming_msg( sock )
	
	begin
		if sock.eof? 
			puts "#{sock.to_s} closed."
			sock.close
			@descriptors.delete(sock)
			@clients.delete( sock )

		else

			raw_msg = sock.read_nonblock($MAXSIZE)
			process_msg( raw_msg  , sock)

		end
	
	rescue
		puts "ERROR: #{$!}"
	end
end







#----------------
def process_msg( raw_msg , sock ) 
	
		
	if raw_msg.length > 0

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
			end

		else
			
			msg = ''
			extract_msg( raw_msg , msg )
			
						
		end

		
	end
	
end


#-------------
def extract_msg( raw_msg , msg ) 

		fin    		=   ( raw_msg[0] >> 7 ) & 0x01
		rsv1   		=   ( raw_msg[0] >> 6 ) & 0x01
		rsv2   		=   ( raw_msg[0] >> 5 ) & 0x01
		rsv3   		=   ( raw_msg[0] >> 4 ) & 0x01			 
		opcode 		=     raw_msg[0]  & 0x0f
		maskflag   	=   ( raw_msg[1] >> 7 ) & 0x01
		len    		=     raw_msg[1] & 0x7f
		offset 		=   2
		
		if len == 127 
		
			offset += 8
			len =  (raw_msg[2].to_i << 56) + ( raw_msg[3].to_i << 48) \
				 + (raw_msg[4].to_i << 40) + ( raw_msg[5].to_i << 32) \
				 + (raw_msg[6].to_i << 24) + ( raw_msg[7].to_i << 16) \
				 + (raw_msg[8].to_i << 8)  + ( raw_msg[9].to_i )	

		elsif len >= 126
			
			offset += 2
			len = ( raw_msg[2].to_i << 8 ) + raw_msg[3].to_i
			
		end

		mask = []
		(0...4).each { |i|
			mask[i] = raw_msg[offset + i] 
		}
		offset += 4

		if opcode == 0x01 

			(0...len).each { |i|

				msg << ( raw_msg[offset + i] ^ mask[i % 4] ).chr

			}
		end
end



#----------------------------------------
def send_ws_frame( ws , application_data)

	frame = ''

	frame << 0x81

	length = application_data.size
	
	if length <= 125
	  byte2 = length
	  frame << byte2
	
	elsif length < 65536 # write 2 byte length
	  frame << 126
	  frame << [length].pack('n')
	
	else # write 8 byte length
	  frame << 127
	  frame << [length >> 32, length & 0xFFFFFFFF].pack("NN")
	end

	frame << application_data

	ws.write(frame)

end


#------------
def main( argv )

	@descriptors = Array::new

	if argv.length < 1
		puts "Usage: ruby ws_rsocket.rb <port>"
		return
	end

	port = argv[0]
	
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



