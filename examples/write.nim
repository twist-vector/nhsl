#
#
#                     Nimrod Runtime Library
#                   for Serialization Using the
#                       Hessian Protocol
#
#                  (c) Copyright 2011 Tom Krauss
#
# This is a example driver for the Nimrod Hessian module.  This program
# writes Hessian-encoded data to an example file.
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
# Build the Hessian-encoded string of data
var buffer: string = ""

# Booleans...
buffer = buffer & encode(true)
buffer = buffer & encode(false)

# Integers
buffer = buffer & encode(1'i32)
buffer = buffer & encode(-1)
buffer = buffer & encode(-16)
buffer = buffer & encode(47)
buffer = buffer & encode(1000)
buffer = buffer & encode(-1000)
buffer = buffer & encode(2047)
buffer = buffer & encode(262143)
buffer = buffer & encode(262144257)

# Longs
buffer = buffer & encode(0'i64)
buffer = buffer & encode(-8'i64)
buffer = buffer & encode(15'i64)
buffer = buffer & encode(-2048'i64)
buffer = buffer & encode(-256'i64)
buffer = buffer & encode(2047'i64)
buffer = buffer & encode(-262144'i64)
buffer = buffer & encode(262143'i64)

# Floats
buffer = buffer & encode(0.0)
buffer = buffer & encode(1.0)
buffer = buffer & encode(127.0)
buffer = buffer & encode(-128.0)
buffer = buffer & encode(-1.0)
buffer = buffer & encode(-32768.0)
buffer = buffer & encode(32767.0)
buffer = buffer & encode(12.25)
buffer = buffer & encode(214.3)

# Strings
buffer = buffer & encode("Hello world")
buffer = buffer & encode("This is a much longer line.  We need it to be longer than 32 characters to force it to a block.")

# Arrays (lists)
buffer = buffer & encode([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
buffer = buffer & encode([-12345.67, -1.1, 0.0, 1.1, 23456.78])


###############################################################
# Open the test file and read in all the binary data
var FID: File
var status = open(FID, testFilename, fmWrite)
if not status:
  echo("Failed to open binary Hessian test file "&testFilename)
  quit(1)
write(FID, buffer)
close(FID)
