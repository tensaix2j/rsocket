

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


	sock = TCPSocket::new( $config["host"] , $config["port"] )
	str = sock.recv( $MAXSIZE );
	puts str
	sock.close()

end

main( ARGV.length , ARGV )

