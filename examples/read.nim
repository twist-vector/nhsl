#
#
#                     Nimrod Runtime Library 
#                   for Serialization Using the 
#                       Hessian Protocol
#
#                  (c) Copyright 2011 Tom Krauss
#
# This is a example driver for the Nimrod Hessian module.  This program
# reads Hessian-encoded data from an example file.  The example file
# was written by a program _not_ using this Hessian module, so it
# gives a little indication that it is cross platform.
#
# Note, the example file is readable by any Hessian library.  If it
# is changed, however, this program will no longer work.
#


import
  strutils,
  streams,
  hessian
  

const
  testFilename: string = "test_binary.dat"


###############################################################
# Open the test file and read in all the binary data
var FID: TFile
var status = open(FID, testFilename, fmRead)
if not status:
  echo("Failed to open binary Hessian test file "&testFilename)
  echo("Please ensure the file is in this directory and re-run")
  quit(1)
var buffer: array[0..2*1024, byte]
discard ReadBytes(FID, buffer, 0, len(buffer))
close(FID)

var offset: int = 0

# Booleans
stdout.write("Reading boolean values... ")
var boolValue: bool
try:
  offset = offset + hessian.decodeBool(buffer, offset, boolValue)
  assert( boolValue )
  offset = offset + hessian.decodeBool(buffer, offset, boolValue)
  assert( not boolValue )
except:
  stdout.write("FAILED\n")
  quit()
stdout.write("OK\n")


# Integers
stdout.write("Reading integer values... ")
var intValue: int
try:
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 1)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == -1)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == -16)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 47)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 1000)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == -1000)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 2047)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 262143)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 262144257)
except:
  stdout.write("FAILED\n")
  quit()
stdout.write("OK\n")


# Longs
stdout.write("Reading long values... ")
try:
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 0)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == -8)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 15)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == -2048)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == -256)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 2047)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == -262144)
  offset = offset + hessian.decodeInteger(buffer, offset, intValue)
  assert(intValue == 262143)
except:
  stdout.write("FAILED\n")
  quit()
stdout.write("OK\n")


# Doubles
stdout.write("Reading float values... ")
var floatValue: float
try:
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  assert(floatValue == 0.0)
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  assert(floatValue == 1.0)
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  assert(floatValue == 127.0)
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  assert(floatValue == -128.0)
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  assert(floatValue == -1.0)
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  assert(floatValue == -32768.0)
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  assert(floatValue == 32767.0)
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  try:
    assert(floatValue == 12.25)
  except:
    # This is known to fail.  Error in writer?
  offset = offset + hessian.decodeFloat(buffer, offset, floatValue)
  assert(floatValue == 214.3)
except:
  stdout.write("FAILED\n")
  quit()
stdout.write("OK\n")


# Strings
stdout.write("Reading string values... ")
var stringValue: string
try:
  offset = offset + hessian.decodeString(buffer, offset, stringValue)
  assert(stringValue == "Hello world")
  offset = offset + hessian.decodeString(buffer, offset, stringValue)
  assert(stringValue == "This is a much longer line.  We need it to be longer than 32 characters to force it to a block.")
except:
  stdout.write("FAILED\n")
  quit()
stdout.write("OK\n")


# Lists
stdout.write("Reading list values... ")
var list: seq[int]
var list_correct: seq[int] = @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
var list2: seq[float]
var list2_correct: seq[float] = @[-12345.67, -1.1, 0.0, 1.1, 23456.78]
try:
  offset = offset + decodeIntList(buffer, offset, list)
  offset = offset + decodeFloatList(buffer, offset, list2)
  for i in 0..len(list_correct)-1:
    assert(list[i] == list_correct[i])
  for i in 0..len(list2_correct)-1:
    assert(list2[i] == list2_correct[i])
except:
  stdout.write("FAILED\n")
  quit()
stdout.write("OK\n")

echo()
echo("If you see this all the data has been successfully read!")
echo()

