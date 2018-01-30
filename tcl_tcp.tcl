
#-----------
proc on_error { sock err } {

	puts "$sock:$err"
}

#-----------
proc on_data { sock msg } {

	puts "$sock:$msg"
}

#-----------
proc on_close { sock } {

	puts "$sock closed"
}

#-----------
proc on_readable { sock } {

	if { [ catch { set input [gets $sock] } err ] } {
		on_error $sock $err
	}
		
	if { [eof $sock] } {  
		on_close $sock
	    close $sock

	} else {
	    on_data $sock $input 
	}
}

#-----------
proc on_connected { sock addr port } {

	puts "$sock $addr $port connected"

	fileevent $sock readable [list on_readable $sock ]
	fconfigure $sock -buffering none -blocking 0
		
}

#-----------
proc main { argc argv } {

	socket -server on_connected $argv
	puts "Server started at port $argv"
	vwait forever	
}


main $argc $argv


