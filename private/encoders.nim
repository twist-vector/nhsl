
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
    result[0] = cast[char](int8(len(str)))
    for i in 0..len(str)-1:
      result[i+1] = str[i]

  elif len(str) <= 32767:
    result = newString(len(str)+3)
    var temp: int16 = htons(int16(len(str)))
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
  result = result & ( encode(len(value)) )
  for v in items(value):
    result = result & ( encode(v) )


proc encode*(value: openarray[float], asDouble: bool = false): string =
  ## Encodes a list of floats into a string.
  result = newString(1)
  result[0] = 'V'
  result = result & encode("flt")
  result = result & $( encode(len(value)) )
  for v in items(value):
    result = result & $( encode(v) )


proc encode*(time: Time, compact: bool=true): string =
  # Seconds since Unix epoch (as float)
  var seconds = toSeconds(time)

  if compact:
    let minutes: int32 = int32(seconds/60.0)
    var preencode: string = encode(minutes, compact=false)
    result = preencode
    result[0] = '\x4b'
  else:
    let millisec: int64 = int64(seconds*1000.0)
    var preencode: string = encode(millisec, compact=false)
    result = preencode
    result[0] = '\x4a'
