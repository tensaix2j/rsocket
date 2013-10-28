
require 'rubygems'
require 'socket'


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
			msg = sock.gets()
			puts "#{ sock }: #{msg}"
			
			dispatch_msg( msg  , sock)
		end
	
	rescue Exception => e  
		puts "ERROR: #{e.to_s}\n#{e.backtrace() }"
	end
end


#------------
def broadcast ( sock , msg )

	puts "Broadcasting: #{msg}"
	
	@clients.each { |s|

		begin
			s.puts( msg ) if ( s != sock ) 
		rescue
			puts "Unable to write into #{s}. Skipping.."
		end

	}
end


#----------------
def dispatch_msg( msg , sock ) 
	
	msg_arr = msg.split(" ")
	msg_header = msg_arr[0]
	msg_arr.shift()
	msg_payload = msg_arr * " "
		
	# Do shit here. 
	if msg_header[/broadcast/] 

		broadcast(sock, msg_payload )
	end
	
end




#------------
def main( argv )

	@descriptors = Array::new

	if argv.length < 1
		puts "Usage: ruby #{$0} <port>"
		return
	end

	port = argv[0]
	
	@serverSocket = TCPServer.new("", port)
	@serverSocket.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
	@descriptors << @serverSocket
	@clients = []
	printf "TCP Server started on port %d\n", port
	
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



