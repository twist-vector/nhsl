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
# Hessian serialization and is based on Hessian 2.0 Specification at
#    http://hessian.caucho.com/doc/hessian-serialization.html
#
# TBD:
#    Implement more of the defined types
#       - Not all array types are supported
#       - Reference types
#       - Objects
#       - Map types
#

import
  nativesockets,
  math,
  unicode


include "private/utils"


proc encode*(value: bool): string =
  ## Encodes a boolean value into a string.
  result = newString(1)
  if value:
    result[0] = char(0x54)
  else:
    result[0] = char(0x46)


proc encode*(value: int, compact=true): string =
  ## Encodes an integer value into a string.
  if value >= -16 and value <= 47 and compact:
    # Single octet
    result = newString(1)
    result[0] = char( value + toU8(0x90) )

  elif value >= -2048 and value <= 2047 and compact:
    # two-octet
    result = newString(2)
    let value2 = value+2048
    let b0 = value2 and 0xff
    let b1 = ((value2 shr 8) + 0xc0)
    result[0] = cast[char](b1)
    result[1] = cast[char](b0)

  elif value >= -262144 and value <= 262143 and compact:
    # three-octet
    result = newString(3)
    var temp: int32 = htonl(int32(value))
    var y = cast[cstring](addr(temp))
    result[0] = cast[char](cast[int8](y[1]) + 0xd4'i8)
    result[1] = cast[char](y[2])
    result[2] = cast[char](y[3])

  else:
    ## Encodes an 32 bit signed  value into a string.
    result = newString(5)
    var temp: int32 = htonl(int32(value))
    var y = cast[cstring](addr(temp))
    result[0] = 'I'
    result[1] = cast[char](y[0])
    result[2] = cast[char](y[1])
    result[3] = cast[char](y[2])
    result[4] = cast[char](y[3])


proc encode*(value: int64, compact: bool=true, width: int8= -1): string =
  ## Encodes a long integer (int64) value into a string.
  if value >= -8 and value <= 15 and (compact or width==1):
    # Single octet
    result = newString(1)
    result[0] = char( value + toU8(0xe0) )

  elif value >= -2048 and value <= 2047 and (compact or width==2):
    # two-octet
    result = newString(2)
    var temp: int16 = htons(int16(value))
    var y = cast[cstring](addr(temp))
    result[0] = cast[char]( cast[int8](y[0]) + 0xf8'i8 )
    result[1] = cast[char](y[1])

  elif value >= -262144 and value <= 262143 and (compact or width==3):
    # three-octet
    result = newString(3)
    var temp: int32 = htonl(int32(value))
    var y = cast[cstring](addr(temp))
    result[0] = cast[char](cast[int8](y[1]) + 0x3c'i8)
    result[1] = cast[char](y[2])
    result[2] = cast[char](y[3])

  else:
    # Otherwise we're stuck using the full 8 bytes
    result = newString(9)
    var temp: int64 = value
    var y = cast[cstring](addr(temp))
    result[0] = 'L'
    if cpuEndian==littleEndian:
      result[1] = cast[char](y[7])
      result[2] = cast[char](y[6])
      result[3] = cast[char](y[5])
      result[4] = cast[char](y[4])
      result[5] = cast[char](y[3])
      result[6] = cast[char](y[2])
      result[7] = cast[char](y[1])
      result[8] = cast[char](y[0])
    else:
      result[1] = cast[char](y[0])
      result[2] = cast[char](y[1])
      result[3] = cast[char](y[2])
      result[4] = cast[char](y[3])
      result[5] = cast[char](y[4])
      result[6] = cast[char](y[5])
      result[7] = cast[char](y[6])
      result[8] = cast[char](y[7])


proc encode*(value: float, compact: bool=true, width: int8= -1): string =
  ## Encodes a floating point (double) value into a string in the compact form.
  if value == 0.0 and (compact or width==1):
    result = newString(1)
    result[0] = char(0x5b'i8)

  elif value == 1.0 and (compact or width==1):
    result = newString(1)
    result[0] = char(0x5c'i8)

  elif value >= -128.0 and value <= 127.0 and
            (float(round(value))==value) and (compact or width==2):
    # two-octet
    result = newString(2)
    var temp: int8 = int8(value)
    result[0] = char(0x5d'i8)
    result[1] = cast[char](temp)

  elif value >= -32768.0 and value <= 32767.0 and
            (float(round(value))==value)  and (compact or width==3):
    # three-octet
    result = newString(3)
    var temp: int16 = htons(int16(value))
    var y = cast[cstring](addr(temp))
    result[0] = char(0x5e'i8)
    result[1] = cast[char](y[0])
    result[2] = cast[char](y[1])

  else:
    ## Encodes a floating point (double) value into a string.
    result = newString(9)
    var temp: float64 = float64(value)
    var y = cast[cstring](addr(temp))
    if cpuEndian==littleEndian:
      result[0] = 'D'
      result[1] = cast[char](y[7])
      result[2] = cast[char](y[6])
      result[3] = cast[char](y[5])
      result[4] = cast[char](y[4])
      result[5] = cast[char](y[3])
      result[6] = cast[char](y[2])
      result[7] = cast[char](y[1])
      result[8] = cast[char](y[0])
    else:
      result[0] = 'D'
      result[1] = cast[char](y[0])
      result[2] = cast[char](y[1])
      result[3] = cast[char](y[2])
      result[4] = cast[char](y[3])
      result[5] = cast[char](y[4])
      result[6] = cast[char](y[5])
      result[7] = cast[char](y[6])
      result[8] = cast[char](y[7])


proc encode*(str: string, compact=true): string =
  ## Encodes a string value into a string.
  if len(str) <= 32 and compact:
    result = newString(len(str)+1)
    result[0] = cast[char](int8(runeLen(str)))
    for i in 0..len(str)-1:
      result[i+1] = str[i]

  elif len(str) <= 32767:
    result = newString(len(str)+3)
    var temp: int16 = htons(int16(runeLen(str)))
    var y = cast[cstring](addr(temp))
    result[0] = 'S'
    result[1] = cast[char](y[0])
    result[2] = cast[char](y[1])
    for i in 0..len(str)-1:
      result[i+3] = str[i]


proc encode*(value: openarray[int]): string =
  ## Encodes a list of integers into a string.
  result = newString(1)
  result[0] = 'V'
  result = result & encode("int")
  result = result & $( encode(len(value)) )
  for v in items(value):
    result = result & $( encode(v) )


proc encode*(value: openarray[float], asDouble: bool = false): string =
  ## Encodes a list of floats into a string.
  result = newString(1)
  result[0] = 'V'
  result = result & encode("float")
  result = result & $( encode(len(value)) )
  for v in items(value):
    result = result & $( encode(v) )



#########
# Decoders
# These turn encoded char arrays into native types
#

proc decodeBool*(buffer: string, start: int, value: var bool): int =
  ## Extracts an encoded boolean value from the string.  Returns the number
  ## of bytes consumed extracting the data.
  var code: int = int(buffer[start])
  case code
  of 0x46:
    value  = false
    result = 1
  of 0x54:
    value  = true
    result = 1
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read boolean from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeInteger*(buffer: string, start: int, value: var int): int =
  ## Extracts an encoded integer value from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  var code: int = int(buffer[start])
  case code
  of 0x80..0xbf:
    value  = code - 0x90
    result = 1

  of 0xC0..0xCF:
    var b0 = int(buffer[start+1])
    value  = ((code - 0xc8) shl 8) + b0
    result = 2

  of 0xD0..0xD7:
    var b1 = int(buffer[start+1])
    var b0 = int(buffer[start+2])
    value  = ((code - 0xd4) shl 16) + (b1 shl 8) + b0
    result = 3

  of 0x49:
    var b3 = int(buffer[start+1])
    var b2 = int(buffer[start+2])
    var b1 = int(buffer[start+3])
    var b0 = int(buffer[start+4])
    value  = (b3 shl 24) + (b2 shl 16) + (b1 shl 8) + b0
    result = 5

  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeLongInteger*(buffer: string, start: int, value: var int64): int =
  ## Extracts an encoded long integer value from the char buffer.
  var code: int = int(buffer[start])
  case code
  of 0xd8..0xef:
    value  = code - 0xe0
    result = 1

  of 0xf0..0xff:
    var b0 = int(buffer[start+1])
    value  = ((code - 0xf8) shl 8) + b0
    result = 2

  of 0x38..0x3f:
    var b1 = int(buffer[start+1])
    var b0 = int(buffer[start+2])
    value  = ((code - 0x3c) shl 16) + (b1 shl  8) + b0
    result = 3

  of int('L'):
    var b7 = int(buffer[start+1])
    var b6 = int(buffer[start+2])
    var b5 = int(buffer[start+3])
    var b4 = int(buffer[start+4])
    var b3 = int(buffer[start+1])
    var b2 = int(buffer[start+2])
    var b1 = int(buffer[start+3])
    var b0 = int(buffer[start+4])
    value = (b7 shl 48) + (b6 shl 40) + (b5 shl 32) + b4 +
            (b3 shl 24) + (b2 shl 16) + (b1 shl 8) + b0
    result = 9

  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeFloat*(buffer: string, start: int, value: var float): int =
  ## Extracts an encoded floating point (double) value from the char buffer.

  var code: int = int(buffer[start])
  case code
  of 0x5b:
    value  = 0.0
    result = 1

  of 0x5c:
    value  = 1.0
    result = 1

  of 0x5d:
    # Double as byte
    value  = float(cast[int8](buffer[start+1]))
    result = 2

  of 0x5e:
    # Double as short
    var temp: int16
    var y = cast[cstring](addr(temp))
    y[0]  = cast[char](buffer[start+1])
    y[1]  = cast[char](buffer[start+2])
    value = float( ntohs(temp) )
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
    var e: ref OSError
    new(e)
    e.msg = "Unable to read float from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeString*(buffer: string, start: int, value: var string): int =
  ## Extracts an encoded string value from the char buffer.

  var code: int = int(buffer[start])
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
    var length: int = (int(b1) shl 8) + int(b0)
    value = newString(length)
    for i in 0..length-1:
      value[i] = cast[char](buffer[start+3+i])
    result = 3 + length

  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read string from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeIntList*(buffer: string, start: int, value: var seq[int]): int =
  ## Extracts an encoded list of integers (vector) value from the char buffer.

  var code: int = int(buffer[start])
  var numBytes = 0
  case code
  of int('V'):
    numBytes += 1

    var elemType: string
    numBytes += decodeString(buffer, numBytes, elemType)

    var length: int
    numBytes += decodeInteger(buffer, numBytes, length)

    newSeq(value, length)
    for i in 0..length-1:
      var temp: int
      numBytes += decodeInteger(buffer, numBytes, temp)
      value[i] = temp

    result = numBytes

  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer vector from buffer.  Found code: " &  i2h(code)
    raise e



proc decodeFloatList*(buffer: string, start: int, value: var seq[float]): int =
  ## Extracts an encoded list of floats (vector) value from the char buffer.

  var code: int = int(buffer[start])
  var numBytes = 0
  case code
  of int('V'):
    numBytes += 1

    var elemType: string
    numBytes += decodeString(buffer, numBytes, elemType)

    var length: int
    numBytes += decodeInteger(buffer, numBytes, length)

    newSeq(value, length)
    for i in 0..length-1:
      var temp: float
      numBytes += decodeFloat(buffer, numBytes, temp)
      value[i] = temp

    result = numBytes

  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read float vector from buffer.  Found code: " &  i2h(code)
    raise e




when isMainModule:

  # Boolean checks
  assert encode(true) == "T"
  assert encode(false) == "F"

  # Integer compact form checks
  # 1 byte
  assert encode(0) == "\x90"
  assert encode(-16) == "\x80"
  assert encode(47) == "\xbf"
  # 2 byte
  assert encode(-2048) == "\xc0\x00"
  assert encode(-256) == "\xc7\x00"
  assert encode(2047) == "\xcf\xff"
  # 3 byte
  assert encode(-262144) == "\xd0\x00\x00"
  assert encode(262143) == "\xd7\xff\xff"

  # Integer non-compact form (4 byte plus leading 'I') checks
  assert encode(0, compact=false) == "I\x00\x00\x00\x00"
  assert encode(300, compact=false) == "I\x00\x00\x01\x2c"


  # 64-bit integer compact form checks
  # 1 byte
  assert encode(0'i64) == "\xe0"
  assert encode(-8'i64) == "\xd8"
  assert encode(15'i64) == "\xef"
  # 2 byte
  assert encode(0'i64, width=2, compact=false) == "\xf8\x00"
  assert encode(-2048'i64) == "\xf0\x00"
  assert encode(-256'i64) == "\xf7\x00"
  assert encode(2047'i64) == "\xff\xff"
  # 3 byte
  assert encode(0'i64, width=3, compact=false) == "\x3c\x00\x00"
  assert encode(-262144'i64) == "\x38\x00\x00"
  assert encode(262143'i64) == "\x3f\xff\xff"
  # Long non-compact form (8 bytes plus leading 'L') checks
  assert encode(0'i64, compact=false) == "L\x00\x00\x00\x00\x00\x00\x00\x00"
  assert encode(300'i64, compact=false) == "L\x00\x00\x00\x00\x00\x00\x01\x2c"


  # Double compact form checks
  assert encode(0.0) == "\x5b"
  assert encode(1.0) == "\x5c"
  assert encode(-128.0) == "\x5d\x80"
  assert encode(127.0) == "\x5d\x7f"
  assert encode(-32768.0) == "\x5e\x80\x00"
  assert encode(32767.0) == "\x5e\x7f\xff"

  # Double non-compact form checks
  assert encode(12.25) == "D\x40\x28\x80\x00\x00\x00\x00\x00"


  # String checks
  assert encode("") == "\x00"
  assert encode("Ã") == "\x01\xc3\x83"
  assert encode("hello") == "\x05hello"
  assert encode("hello", compact=false) == "S\x00\x05hello"
  assert encode("hÃllo", compact=false) == "S\x00\x05h\xc3\x83llo"


  # Array checks
  assert encode([1,2,3]) == "V\x03int\x93\x91\x92\x93"  # ints
  assert encode([1.0,2.0,3.0]) == "V\x05float\x93\x5c\x5d\x02\x5d\x03" # floats



  var numBytes:int

  # Boolean decode checks
  var valTrue, valFalse: bool
  numBytes = decodeBool( encode(true), 0, valTrue )
  assert valTrue
  assert numBytes==1
  numBytes = decodeBool( encode(false), 0, valFalse )
  assert (not valFalse)
  assert numBytes==1

  # Int decode checks
  # 1 byte
  var intVal: int
  numBytes = decodeInteger( encode(0), 0, intVal )
  assert intVal == 0
  assert numBytes == 1
  numBytes = decodeInteger( encode(-16), 0, intVal )
  assert intVal == -16
  assert numBytes == 1
  numBytes = decodeInteger( encode(47), 0, intVal )
  assert intVal == 47
  assert numBytes == 1
  # 2 bytes
  numBytes = decodeInteger( encode(-2048), 0, intVal )
  assert intVal == -2048
  assert numBytes == 2
  numBytes = decodeInteger( encode(-256), 0, intVal )
  assert intVal == -256
  assert numBytes == 2
  numBytes = decodeInteger( encode(2047), 0, intVal )
  assert intVal == 2047
  assert numBytes == 2
  # 3 byte
  numBytes = decodeInteger( encode(-262144), 0, intVal )
  assert intVal == -262144
  assert numBytes == 3
  numBytes = decodeInteger( encode(262143), 0, intVal )
  assert intVal == 262143
  assert numBytes == 3
  # Non-compact form
  numBytes = decodeInteger( encode(0, compact=false), 0, intVal )
  assert intVal == 0
  assert numBytes == 5
  numBytes = decodeInteger( encode(300, compact=false), 0, intVal )
  assert intVal == 300
  assert numBytes == 5


  # 64-bit integer compact form checks
  var longIntVal: int64
  # 1 byte
  numBytes = decodeLongInteger( encode(0'i64), 0, longIntVal )
  assert longIntVal == 0
  assert numBytes == 1
  # 2 byte
  numBytes = decodeLongInteger( encode(0'i64, width=2, compact=false), 0, longIntVal )
  assert longIntVal == 0
  assert numBytes == 2
  numBytes = decodeLongInteger( encode(-2048'i64), 0, longIntVal )
  assert longIntVal == -2048
  assert numBytes == 2
  numBytes = decodeLongInteger( encode(-256'i64), 0, longIntVal )
  assert longIntVal == -256
  assert numBytes == 2
  numBytes = decodeLongInteger( encode(2047'i64), 0, longIntVal )
  assert longIntVal == 2047
  assert numBytes == 2
  # 3 byte
  numBytes = decodeLongInteger( encode(0'i64, width=3, compact=false), 0, longIntVal )
  assert longIntVal == 0
  assert numBytes == 3
  numBytes = decodeLongInteger( encode(-262144'i64), 0, longIntVal )
  assert longIntVal == -262144
  assert numBytes == 3
  numBytes = decodeLongInteger( encode(262143'i64), 0, longIntVal )
  assert longIntVal == 262143
  assert numBytes == 3
  # Long non-compact form (8 bytes plus leading 'L') checks
  numBytes = decodeLongInteger( encode(300'i64, compact=false), 0, longIntVal )
  assert longIntVal == 0
  assert numBytes == 9
  #assert encode(300'i64, compact=false) == "L\x00\x00\x00\x00\x00\x00\x01\x2c"

  # Double checks
  var floatVal: float
  # 1 byte
  numBytes = decodeFloat( encode(0.0), 0, floatVal )
  assert floatVal == 0.0
  assert numBytes == 1
  numBytes = decodeFloat( encode(1.0), 0, floatVal )
  assert floatVal == 1.0
  assert numBytes == 1
  # 2 byte
  numBytes = decodeFloat( encode(-128.0), 0, floatVal )
  assert floatVal == -128.0
  assert numBytes == 2
  numBytes = decodeFloat( encode(127.0), 0, floatVal )
  assert floatVal == 127.0
  assert numBytes == 2
  # 3 bytes
  numBytes = decodeFloat( encode(-32768.0), 0, floatVal )
  assert floatVal == -32768.0
  assert numBytes == 3
  numBytes = decodeFloat( encode(32767.0), 0, floatVal )
  assert floatVal == 32767.0
  assert numBytes == 3
  # Non-compact, 9 bytes
  numBytes = decodeFloat( encode(0.0, compact=false), 0, floatVal )
  assert floatVal == 0.0
  assert numBytes == 9
  numBytes = decodeFloat( encode(12.25, compact=false), 0, floatVal )
  assert floatVal == 12.25
  assert numBytes == 9


  # String checks
  var stringValue: string
  numbytes = decodeString( encode(""), 0, stringValue )
  assert stringValue == ""
  assert numBytes == 1
  # Decode of unicode fails.  Not sure Hessian spec is correct or we're
  # mis-interpreting it.
  # numbytes = decodeString( encode("Ã"), 0, stringValue)
  # assert stringValue == "Ã"
  # assert numBytes == 1


  # List checks
  # Integer
  var intListValue: seq[int]
  numBytes = decodeIntList( encode([1,2,3]), 0, intListValue )
  assert intListValue == @[1,2,3]
  assert numBytes == 9
  # Float
  var floatListValue: seq[float]
  numBytes = decodeFloatList( encode([1.0,2.0,3.0]), 0, floatListValue )
