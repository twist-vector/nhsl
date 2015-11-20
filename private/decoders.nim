


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
    var b0, b1, b2, b3, b4, b5, b6, b7: int64
    if cpuEndian==littleEndian:
      b7 = int64(buffer[start+1])
      b6 = int64(buffer[start+2])
      b5 = int64(buffer[start+3])
      b4 = int64(buffer[start+4])
      b3 = int64(buffer[start+5])
      b2 = int64(buffer[start+6])
      b1 = int64(buffer[start+7])
      b0 = int64(buffer[start+8])
    else:
      b0 = int64(buffer[start+1])
      b1 = int64(buffer[start+2])
      b2 = int64(buffer[start+3])
      b3 = int64(buffer[start+4])
      b4 = int64(buffer[start+5])
      b5 = int64(buffer[start+6])
      b6 = int64(buffer[start+7])
      b7 = int64(buffer[start+8])

    value = (b7 shl 56) + (b6 shl 48) + (b5 shl 40) + (b4 shl 32) +
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
  var numBytes = start
  case code
  of int('V'):
    numBytes += 1 # For the 'V'

    var elemType: string
    numBytes += decodeString(buffer, numBytes, elemType)

    var length: int
    numBytes += decodeInteger(buffer, numBytes, length)

    newSeq(value, length)
    for i in 0..length-1:
      var temp: int
      numBytes += decodeInteger(buffer, numBytes, temp)
      value[i] = temp

    result = numBytes-start

  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer vector from buffer.  Found code: " &  i2h(code)
    raise e



proc decodeFloatList*(buffer: string, start: int, value: var seq[float]): int =
  ## Extracts an encoded list of floats (vector) value from the char buffer.

  var code: int = int(buffer[start])
  var numBytes = start
  case code
  of int('V'):
    numBytes += 1 # For the 'V'

    var elemType: string
    numBytes += decodeString(buffer, numBytes, elemType)

    var length: int
    numBytes += decodeInteger(buffer, numBytes, length)

    newSeq(value, length)
    for i in 0..length-1:
      var temp: float
      numBytes += decodeFloat(buffer, numBytes, temp)
      value[i] = temp

    result = numBytes-start

  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read float vector from buffer.  Found code: " &  i2h(code)
    raise e


proc decodeTime*(buffer: string, start: int, value: var Time): int =
  var code = buffer[start]
  var numBytes = start
  case code
  of '\x4b':
    var buffdup = buffer
    buffdup[start] = '\x49' # make it look like an int32 so we can re-use decoder
    var tMins: int
    numBytes += decodeInteger(buffdup,start,tMins)
    value = fromSeconds( float(tMins)*60.0 )
    result = numBytes-start

  of '\x4a':
    var buffdup = buffer
    buffdup[start] = '\x4c' # make it look like an int64 so we can re-use decoder
    var tMilli: int64
    numBytes += decodeLongInteger(buffdup,start,tMilli)
    value = fromSeconds( float(tMilli)/1000.0 )
    result = numBytes-start

  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read time from buffer.  Found code: " &  i2h(int(code))
    raise e
