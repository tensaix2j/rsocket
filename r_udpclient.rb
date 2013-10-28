




require 'rubygems'
require 'socket'


$MAXSIZE = 65536

$config = {
	"host" 	=> "localhost",
	"port"	=> "10000"
}

def main( argc, argv )

	$config = $config.merge( Hash[*argv] )

	p $config



	sock = UDPSocket.new
	sock.send "testing123", 0 , $config["host"], $config["port"]

	# Blocking read
	p sock.recvfrom($MAXSIZE)  


end

main( ARGV.length , ARGV )

