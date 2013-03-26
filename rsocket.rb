
require 'rubygems'
require 'socket'


#--------
def accept_new_connection( sock )
	
	newsock = sock.accept
	@descriptors << newsock
	
	puts "#{newsock.to_s} connected."
	
end

#-----------
def settle_incoming_msg( sock )
	
	if sock.eof? 
		puts "#{sock.to_s} closed."
		sock.close
		@descriptors.delete(sock)
	else
		msg = sock.gets()
		puts "Received: #{msg}"
		dispatch_msg( msg  , sock)
	end
end


#----------------
def dispatch_msg( msg , sock ) 
	
	msg_arr = msg.split(" ")
	msg_header = msg_arr[0]
	msg_arr.shift()
	msg_payload = msg_arr * " "
		
	# Do shit here. 


	
end




#------------
def main( argv )

	@descriptors = Array::new

	if argv.length < 1
		puts "Usage: ruby rsocket.rb <port>"
		return
	end

	port = argv[0]
	
	@serverSocket = TCPServer.new("", port)
	@serverSocket.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
	@descriptors << @serverSocket
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



