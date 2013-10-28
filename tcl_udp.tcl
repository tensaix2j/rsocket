
package require udp

#-----------
proc on_data { sock } {

	puts "<on_data>"

	set packet [ read $sock ]
	set peer  [ fconfigure $sock -peer ]

	set sender_host [ lindex $peer 0 ]
	set sender_port [ lindex $peer 1 ]

	puts "$sender_host $sender_port : $packet"

	return
}




#-----------
proc main { argc argv } {

	set sock [ udp_open $argv ]
	fileevent $sock readable [list on_data $sock ]

	fconfigure $sock -buffering none -translation binary
	
	puts "Server started at port $argv"
	
	vwait forever	
}


main $argc $argv


