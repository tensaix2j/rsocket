
#include <stdio.h>
#include <winsock2.h>
#include <vector>

using namespace std;

int main() {
	
	struct sockaddr_in	server_address;
		
	int port = 10000;
	
	FD_SET ReadSet;
	FD_SET WriteSet;

	vector <SOCKET> client_list;
	

	// Step 1 , WSAStartup
	WSADATA  WSA_Data;
	WSAStartup (0x0202, & WSA_Data);

	// Step 2 , create a sock
	SOCKET sock = WSASocket( AF_INET, SOCK_STREAM, 0, NULL, 0 , WSA_FLAG_OVERLAPPED );
	if (sock == INVALID_SOCKET ) {
		int errorno = WSAGetLastError();
		printf("socket: Error no %d\n", errorno );
		exit(EXIT_FAILURE);
	}

	// Step 3 , Prepare server address family.
	printf("Ready to prepare server addresses\n");


	memset((char *) &server_address, 0, sizeof(server_address));
	server_address.sin_family = AF_INET;
	server_address.sin_addr.s_addr = htonl(INADDR_ANY);
	server_address.sin_port = htons(port);


	// Step 4, Bind 
	printf("Ready to bind\n");


	if (bind(sock, (struct sockaddr *) &server_address, sizeof(server_address)) < 0 ) {
		
		int errorno = WSAGetLastError();
		printf("bind: Error no %d\n", errorno );
		exit(EXIT_FAILURE);
	}
	

	// Step 5, Listen
	printf("Ready to listen at port %d\n", port);
	listen( sock , 5 );

	
	
	// Step 6: Change the socket mode on the listening socket from blocking to non-block 
	ULONG NonBlock = 1;
    if (ioctlsocket( sock , FIONBIO, &NonBlock) == SOCKET_ERROR) {
         printf("ioctlsocket() failed \n");
         exit(EXIT_FAILURE);
    }
	

	// Step 7, Select Loop
	char buffer[1024];

	while (1) {

		FD_ZERO(&ReadSet);
		FD_ZERO(&WriteSet);

		FD_SET( sock, &ReadSet);
		for ( int i = 0 ; i < client_list.size() ; i++ ) {
			FD_SET( client_list[i] , &ReadSet);
		}


	
		int readsocks = select( 0, &ReadSet, &WriteSet, NULL, 0);
		
		if (readsocks == SOCKET_ERROR ) {

			int errorno = WSAGetLastError();
			printf("readsocks: Error no %d\n", errorno );
			exit(EXIT_FAILURE);
		}
		
		if ( readsocks == 0) {
			/* Nothing ready to read, just show that
			   we're alive */
			
		} else {

			// The sock server is in one of the ISSET in ReadSet
			// This means it receives some connection request.

			if (FD_ISSET(sock,&ReadSet )) {
				

				// Accept the client's connection request 
				int connection = accept(sock, NULL, NULL);
	
				if (connection == INVALID_SOCKET) {
					int errorno = WSAGetLastError();
					printf("accept: Error no %d\n", errorno );
					exit(EXIT_FAILURE);
				}

				if (ioctlsocket(connection, FIONBIO, &NonBlock) == SOCKET_ERROR)
				{
				   printf("ioctlsocket(FIONBIO) failed with error %d\n", WSAGetLastError());
				   exit(EXIT_FAILURE);
				}
				
				// Add the socket client into the array of client list
				printf("Client added %x\n", connection);
				client_list.push_back( connection );
				
			}	
			
			

			// For each of the client, need to see if these sockets are in the ISSET of ReadSet on the last Select()
			for ( int i = 0 ; i < client_list.size() ; i++ ) {
				
				if ( FD_ISSET( client_list[i] , &ReadSet ) ) {
					
					// If it is , read and print
					int n = recv( client_list[i], buffer, 1024, 0 );
					buffer[n] = 0;
					printf("Received: %s", buffer) ;
				} 
			}


			
		}

	
	}


	return 0;

}