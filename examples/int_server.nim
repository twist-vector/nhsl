#
#
#                     Nimrod Runtime Library 
#                   for Serialization Using the 
#                       Hessian Protocol
#
#                  (c) Copyright 2011 Tom Krauss
#
#
# This is an example server which uses the Hessian protocaol
# for communication.  It opens a port (9988, see below) and
# waits for a connect.  Once a connection is received a 
# greeting is sent as a normal string.  The server then 
# waits for Hessian-encoded integers to be sent.  Each
# received integer is decoded, squared and the result re-
# encoded as a Hessian integer and sent b ack to the client.
#

import
  strutils, 
  os, osproc,
  sockets,
  hessian
  
const
  port: int = 9988  
  
  
var server = socket(AF_INET)
if server == InvalidSocket: OSError()

bindAddr(server, TPort(port))
listen(server)

echo("Server waiting for client on port $#" % $port)
while true:
  var client = server.accept()
  echo("Have connection")
  client.send("Hello\n")
  while true:
    var encodedInt = client.recv()
    if len(encodedInt)<=0:
      break
    var num: int
    discard decodeInteger(encodedInt,0,num)
    echo("   Received: $#" % $num)
    client.send( encode(num*num) )
server.close()

