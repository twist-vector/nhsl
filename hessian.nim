#
#
#                     Nimrod Runtime Library 
#                   for Serialization Using the 
#                       Hessian Protocol
#
#                  (c) Copyright 2011 Tom Krauss
#
#
# This module is a partial implementation of the Hessian binary protocol.
# Hessian is a compact binary protocol for cross-platform web services and 
# messaging.  It allows you to represent binary data (integers, floats, lists
# objects, etc.) in a very compact form.  This allows storage or communication
# to be small and fast. 
#
# This is only a partial implementation of the Hessian protocol.  It implements 
# Hessian serialization and is based on Hessian 2.0 Draft Specification at 
#    http://caucho.com/resin-3.1/doc/hessian-2.0-spec.xtp
#
# TBD:
#    Implement the Hessian standard rather than the draft.
#    Implement more of the defined types
#

import
  strutils,
  streams,
  math



#############################################################
# Support procedures.  These are used internally (to the module)
#
proc i2h(x: int): string =
  result = "0x" & toHex(x,2)

proc swap(x: int16): int16 =
  result = x
  var y = cast[cstring](addr(result))
  swap(y[0], y[1])


proc swap(x: float32): float32 =
  result = x
  var y = cast[cstring](addr(result))
  swap(y[0], y[3])
  swap(y[1], y[2])


proc swap(x: float64): float64 =
  result = x
  var y = cast[cstring](addr(result))
  swap(y[0], y[7])
  swap(y[1], y[6])
  swap(y[2], y[5])
  swap(y[3], y[4])


proc signedToUnigned(x: byte): int = 
  if x >= 0:
    result = x
  else:
    result = 256 + x

#
#############################################################


#############################################################
# These procedures are the externally-callable routines that
# implement the protocol.
#



#########
# Encoders
# These turn native types into byte arrays.  There is only one "encode"
# procedure which is overloaded for all the various types
#
proc encode*(value: bool): seq[byte] =
  ## Encodes a boolean value into a byte buffer.
  result = @[]
  if value:
    result.add(0x54'i8)
  else:
    result.add(0x46'i8)
    

proc encode*(value: int): seq[byte] =
  result = @[]
  
  if value >= -16 and value <= 47:
    # Single octet
    result.add(int8(value) + 0x90'i8)

  elif value >= -2048 and value <= 2047:
    # two-octet
    var temp: int16 = int16(value)
    var y = cast[cstring](addr(temp))
    result.add(cast[byte](y[1]) + byte(0xc8'i8))
    result.add(cast[byte](y[0]))

  elif value >= -262144 and value <= 262143:
    # three-octet
    var temp: int32 = int32(value)
    var y = cast[cstring](addr(temp))
    result.add(cast[byte](y[2]) + byte(0xd4'i8))
    result.add(cast[byte](y[1]))
    result.add(cast[byte](y[0]))
    
  else:
    # 32-bit signed
    var temp: int32 = int32(value)
    var y = cast[cstring](addr(temp))
    result.add(0x49'i8)
    result.add(cast[byte](y[3]))
    result.add(cast[byte](y[2]))
    result.add(cast[byte](y[1]))
    result.add(cast[byte](y[0]))


proc encode*(value: int64): seq[byte] =
  result = @[]

  if value >= -8 and value <= 15:
    # Single octet
    result.add(int8(value) + 0xe0'i8)

  elif value >= -2048 and value <= 2047:
    # two-octet
    var temp: int16 = int16(value)
    var y = cast[cstring](addr(temp))
    result.add(cast[byte](y[1]) + byte(0xf8'i8))
    result.add(cast[byte](y[0]))

  elif value >= -262144 and value <= 262143:
    # three-octet
    var temp: int32 = int32(value)
    var y = cast[cstring](addr(temp))
    result.add(cast[byte](y[2]) + byte(0x3c'i8))
    result.add(cast[byte](y[1]))
    result.add(cast[byte](y[0]))

  elif value >= -2147483648 and value <= 2147483647:
    # 32-bit signed
    var temp: int32 = int32(value)
    var y = cast[cstring](addr(temp))
    result.add(0x77'i8)
    result.add(cast[byte](y[3]))
    result.add(cast[byte](y[2]))
    result.add(cast[byte](y[1]))
    result.add(cast[byte](y[0]))

  else:
    # Otherwise we're stuck using the full 8 bytes
    var temp: int64 = int64(value)
    var y = cast[cstring](addr(temp))
    result.add(0x4c'i8)
    result.add(cast[byte](y[7]))
    result.add(cast[byte](y[6]))
    result.add(cast[byte](y[5]))
    result.add(cast[byte](y[4]))
    result.add(cast[byte](y[3]))
    result.add(cast[byte](y[2]))
    result.add(cast[byte](y[1]))
    result.add(cast[byte](y[0]))


proc encode*(value: float, asDouble: bool = true): seq[byte] =
  result = @[]

  if value == 0.0:
    result.add(0x67'i8)

  elif value == 1.0:
    result.add(0x68'i8)

  elif value >= -128.0 and value <= 127.0 and (float(round(value))==value):
    # two-octet
    result.add(0x69'i8)
    result.add(cast[byte](int8(value)))
    
  elif value >= -32768.0 and value <= 32767.0  and (float(round(value))==value):
    # three-octet
    var temp: int16 = int16(value)
    var y = cast[cstring](addr(temp))
    result.add(0x6a'i8)
    result.add(cast[byte](y[1]))
    result.add(cast[byte](y[0]))

  else:
    if asDouble:
        # 9-octet
        var temp: float64 = float64(value)
        var y = cast[cstring](addr(temp))
        result.add(0x44'i8)
        result.add(cast[byte](y[7]))
        result.add(cast[byte](y[6]))
        result.add(cast[byte](y[5]))
        result.add(cast[byte](y[4]))
        result.add(cast[byte](y[3]))
        result.add(cast[byte](y[2]))
        result.add(cast[byte](y[1]))
        result.add(cast[byte](y[0]))
    else:
      # 5-octet
      var temp: float32 = float32(value)
      var y = cast[cstring](addr(temp))
      result.add(0x6b'i8)
      result.add(cast[byte](y[3]))
      result.add(cast[byte](y[2]))
      result.add(cast[byte](y[1]))
      result.add(cast[byte](y[0]))
    

proc encode*(str: string): seq[byte] =
  result = @[]
  
  if len(str) <= 32:
    result.add(int8(len(str)))
    for c in items(str):
      result.add(cast[byte](c))
      
  elif len(str) <= 32767:
    var temp: int16 = int16(len(str))
    var y = cast[cstring](addr(temp))
    result.add(0x53'i8)
    result.add(cast[byte](y[1]))
    result.add(cast[byte](y[0]))
    for c in items(str):
      result.add(cast[byte](c))
    

proc encode*(value: openarray[int]): seq[byte] =
  result = @[]

  result.add(0x56'i8)
  result.add(0x6e'i8)  # Don't care about data type code
  result.add( encode(len(value)) )
  for v in items(value):
    result.add( encode(v) )
  result.add(0x7a'i8) # Trailing 'z'


proc encode*(value: openarray[float], asDouble: bool = false): seq[byte] =
  result = @[]

  result.add(0x56'i8)
  result.add(0x66'i8)  # Don't care about data type code
  result.add( encode(len(value)) )
  for v in items(value):
    result.add( encode(v, asDouble) )
  result.add(0x7a'i8) # Trailing 'z'


#########
# Decoders
# These turn encoded byte arrays into native types
#

proc decodeBool*(buffer: openarray[byte], start: int, value: var bool): int =
  ## Extracts an encoded boolean value from the byte buffer.
  
  var code: int = buffer[start]
  case code
  of 0x46:
    value  = false
    result = 1
  of 0x54:
    value  = true
    result = 1
  else:
    var e: ref EOS
    new(e)
    e.msg = "Unable to read boolean from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeInteger*(buffer: openarray[byte], start: int, value: var int): int =
  ## Extracts an encoded integer (including longs) value from the byte buffer.
  var code: int = signedToUnigned(buffer[start])
  
  case code
  of 0x80..0xbf:
    value  = code - 0x90
    result = 1
    
  of 0xC0..0xCF:
    var b0 = signedToUnigned(buffer[start+1])
    value  = ((code - 0xc8) shl 8) + b0 
    result = 2
    
  of 0xD0..0xD7:
    var b1 = signedToUnigned(buffer[start+1])
    var b0 = signedToUnigned(buffer[start+2])
    value  = ((code - 0xd4) shl 16) + (b1 shl 8) + b0
    result = 3
  
  of 0x49:
    var b3 = signedToUnigned(buffer[start+1])
    var b2 = signedToUnigned(buffer[start+2])
    var b1 = signedToUnigned(buffer[start+3])
    var b0 = signedToUnigned(buffer[start+4])
    value  = (b3 shl 24) + (b2 shl 16) + (b1 shl 8) + b0
    result = 5

  of 0xd8..0xef:
    value  = code - 0xe0
    result = 1

  of 0xf0..0xff:
    var b0 = signedToUnigned(buffer[start+1])
    value  = ((code - 0xf8) shl 8) + b0
    result = 2

  of 0x38..0x3f:
    var b1 = signedToUnigned(buffer[start+1])
    var b0 = signedToUnigned(buffer[start+2])
    value  = ((code - 0x3c) shl 16) + (b1 shl  8) + b0
    result = 3
  
  of 0x4c:
    var b7 = signedToUnigned(buffer[start+1])
    var b6 = signedToUnigned(buffer[start+2])
    var b5 = signedToUnigned(buffer[start+3])
    var b4 = signedToUnigned(buffer[start+4])
    var b3 = signedToUnigned(buffer[start+5])
    var b2 = signedToUnigned(buffer[start+6])
    var b1 = signedToUnigned(buffer[start+7])
    var b0 = signedToUnigned(buffer[start+8])
    value  = (b7 shl 56) + (b6 shl 48) + (b5 shl 40) + (b4 shl 32) +
             (b3 shl 24) + (b2 shl 16) + (b1 shl 8) + b0
    result = 9
    
  else:
    var e: ref EOS
    new(e)
    e.msg = "Unable to read integer from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeFloat*(buffer: openarray[byte], start: int, value: var float): int =
  ## Extracts an encoded floating point (double) value from the byte buffer.

  var code: int = signedToUnigned(buffer[start])
  case code
  of 0x67:
    value  = 0.0
    result = 1

  of 0x68:
    value  = 1.0
    result = 1
   
  of 0x69:
    # Double as byte
    value  = float(buffer[start+1])
    result = 2
    
  of 0x6a:
    # Double as short
    var temp: int16 = 0'i16
    var y = cast[cstring](addr(temp))
    y[0] = cast[char](buffer[start+1])
    y[1] = cast[char](buffer[start+2])
    if cpuEndian==littleEndian: temp = swap(temp)
    value = float(temp)
    result = 3

  of 0x6b:
    # Double as float32
    var temp: float32 = 0.0
    var y = cast[cstring](addr(temp))
    y[0] = cast[char](buffer[start+1])
    y[1] = cast[char](buffer[start+2])
    y[2] = cast[char](buffer[start+3])
    y[3] = cast[char](buffer[start+4])
    if cpuEndian==littleEndian: temp = swap(temp)
    value = float(temp)
    result = 5

  of 0x44:
    var temp: float64
    var y = cast[cstring](addr(temp))
    y[0] = cast[char](buffer[start+1])
    y[1] = cast[char](buffer[start+2])
    y[2] = cast[char](buffer[start+3])
    y[3] = cast[char](buffer[start+4])
    y[4] = cast[char](buffer[start+5])
    y[5] = cast[char](buffer[start+6])
    y[6] = cast[char](buffer[start+7])
    y[7] = cast[char](buffer[start+8])
    if cpuEndian==littleEndian: temp = swap(temp)
    value = float(temp)
    result = 9
    
  else:
    var e: ref EOS
    new(e)
    e.msg = "Unable to read float from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeString*(buffer: openarray[byte], start: int, value: var string): int =
  ## Extracts an encoded string value from the byte buffer.

  var code: int = signedToUnigned(buffer[start])
  case code
  of 0x00..0x1f:
    # UTF-8 string of length between 0 and 32
    var length = code
    value = newString(length)
    for i in 0..length-1:
      value[i] = cast[char](buffer[start+1+i])
    result = 1 + length
    
  of 0x53:
    # Final string chunk
    var b1 = buffer[start+1]
    var b0 = buffer[start+2]
    var length: int = (b1 shl 8) + b0
    value = newString(length)
    for i in 0..length-1:
      value[i] = cast[char](buffer[start+3+i])
    result = 3 + length
    
  else:
    var e: ref EOS
    new(e)
    e.msg = "Unable to read string from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeIntList*(buffer: openarray[byte], start: int, value: var seq[int]): int =
  ## Extracts an encoded list of integers (vector) value from the byte buffer.
  
  var code: int = signedToUnigned(buffer[start])
  var offset: int = 1
  case code
  of 0x56:
    # Not actually verifying the type code here
    #var typeCode: int = int(buffer[start+offset])
    offset = offset + 1
  
    var length: int
    offset = offset + decodeInteger(buffer, start+offset, length)
    
    newSeq(value, length)
    for i in 0..length-1:
      var temp: int
      offset = offset + decodeInteger(buffer, start+offset, temp)
      value[i] = temp
    # Strip of ending 'z'
    offset = offset + 1

    result = offset

  else:
    var e: ref EOS
    new(e)
    e.msg = "Unable to read integer vector from buffer.  Found code: " &  i2h(code)
    raise e



proc decodeFloatList*(buffer: openarray[byte], start: int, value: var seq[float]): int =
  ## Extracts an encoded list of floats (vector) value from the byte buffer.

  var code: int = signedToUnigned(buffer[start])
  var offset: int = 1
  case code
  of 0x56:
    # Not actually verifying the type code here
    #var typeCode: int = int(buffer[start+offset])
    offset = offset + 1
    
    var length: int
    offset = offset + decodeInteger(buffer, start+offset, length)
    
    newSeq(value, length)
    for i in 0..length-1:
      var temp: float
      offset = offset + decodeFloat(buffer, start+offset, temp)
      value[i] = temp
    # Strip of ending 'z'
    offset = offset + 1
    
    result = offset

  else:
    var e: ref EOS
    new(e)
    e.msg = "Unable to read float vector from buffer.  Found code: " &  i2h(code)
    raise e
