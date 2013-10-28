


require 'rubygems'
require 'socket'

$MAXSIZE = 65536


#-----------
def settle_incoming_msg( udpsock )
	
	begin
		dispatch_msg( udpsock.recvfrom($MAXSIZE) , udpsock )
	
	rescue Exception => e  
		puts "ERROR: #{e.to_s}\n#{e.backtrace() }"
	end
end



#----------------
# msg contains things like:
#    ["testing123", ["AF_INET", 54185, "localhost.localdomain", "127.0.0.1"]]

def dispatch_msg( msg , udpsock ) 
	
	msg_arr = msg[0].split(" ")
	sender_host = msg[1][3]
	sender_port = msg[1][1]

	msg_header = msg_arr[0]
	msg_arr.shift()
	msg_payload = msg_arr * " "
	
	udpsock.send "pong", 0 , sender_host, sender_port

	
end


#------------
def main( argv )

	@descriptors = Array::new

	if argv.length < 1
		puts "Usage: ruby #{$0} <port>"
		return
	end

	port = argv[0]
	
	@serverSocket = UDPSocket.new()
	@serverSocket.bind("", port )
	

	@serverSocket.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
	@descriptors << @serverSocket
	printf "UDP Server started on port %d\n", port

	
	
	# Select loop
	while (1)
		
		res = select( @descriptors, nil ,nil ,nil )
		if res != nil
			res[0].each do
				|sock|
				if sock == @serverSocket 
					settle_incoming_msg( sock )
				end
			end
		end
	end


end

main ARGV



