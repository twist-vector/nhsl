#
#
#                     Nimrod Runtime Library 
#                   for Serialization Using the 
#                       Hessian Protocol
#
#                  (c) Copyright 2011 Tom Krauss
#
#
# This is an example client which uses the Hessian protocaol
# for communication.  It connects to a port (9988, see below)
# and receives the string greeting.  It then sends a series of 
# Hessian-encoded integers to the server and receives the
# Hessian-encoded integer results from the server.
#

import
  strutils, os, osproc, sockets,
  hessian
  
const
  port: int = 9988  
  
  
var client = socket(AF_INET)
if client == InvalidSocket: OSError()
client.connect("localhost", TPort(port))

# Retreive greeting
var greeting = client.recv()
echo("Connected")
# Encode and send an int.
for i in countup(-100,100,10):
  echo("   Sending: $#" % $i)
  var encodedNum = encode(i)
  client.send(encodedNum)
  var receivedCode = client.recv()
  var num: int
  discard decodeInteger(receivedCode,0,num)
  echo("      Received: $#" % $num)
client.close()

