


package require websocket


#---------------------------------------
proc onConnected { sock addr port } {
	
	puts "<onConnected> $sock $addr $port"
	variable onConnectedEvtHandler
	fileevent $sock readable [ list onMsgHdl $sock ]
	fconfigure $sock -buffering none -blocking 0
		
}



# Incoming socket msg dispatcher 
#-------------------------
proc onMsgHdl { sock } {
	
	puts "<onMsgHdl>"

	if { [catch { set input [read $sock] } err ] } {
		puts "<onDataArrival> Error in sock. $err"
	}

	
	if { [ lindex $input 0 ] == "GET" } { 
		
		foreach line [ split $input "\n" ]  {
			foreach { k v v2 } [ split $line : ] {
				if { $k != "GET /fmsm HTTP/1.1" } {
					if { $k == "Host" } { 
						dict set hdrs $k [ string trim $v:$v2 ]
					} else { 
						dict set hdrs $k [ string trim $v ]
					}
				}
			}
		}
		
		if { [::websocket::test $::srvSock $sock /hello $hdrs]  } {
			puts "Upgrade"
			::websocket::upgrade $sock
			set ::ws_client_socks($sock) 1
		} 
	} else {

		if { [eof $sock]  } { 
			catch { close $sock }
			onClosed $sock        
		} else {
			onData $sock $input
		}
	}
}

#-----------------------------
proc onClosed { sock  } {

	puts "<onClosed> $sock"

}



#-----------------------------------
proc onData {sock args} {

	puts "<onData>|$sock| |$args|"
	foreach sock [ array names ::ws_client_socks ] { 
		::websocket::send $sock text "hello world yeah [ expr rand() ]" 1
	}
}



#-----------
proc main { argc argv } {

	array set ::ws_client_socks {}
	
	# Setup a websocket server
	if { [ catch { 
		
		set ::srvSock [ socket -server onConnected $argv ]
		::websocket::server $::srvSock
		::websocket::live   $::srvSock /hello onData

	} err ] } {

		puts "$err"
		return -1
	}

	vwait ::forever
}


main $argc $argv

