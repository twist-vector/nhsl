import
  strutils,
  streams,
  hessian


const
  padLength: int = 14



######
# Internal functions to "pretty print" encoded values
#
proc i2s(x: int): string {.procvar.} = 
  result = $x

proc f2s(x: float): string {.procvar.} = 
  result = formatFloat(x, precision=2)

proc i2s(x: byte): string {.procvar.} = 
  result = "0x" & toHex(x,2)

proc showBytes(x: seq[byte]): string =
  var strList = each(x, i2s)
  result = "[" & join(strList, ",") & "]"

proc showList(x: openarray[int]): string =
  var strList = each(x, i2s)
  result = "[" & join(strList, ",") & "]"

proc showList(x: openarray[float]): string =
  var strList = each(x, f2s)
  result = "[" & join(strList, ",") & "]"

######
# Drivers for checking various values/types.  Each procedure encodes the
# value, writes out the resulting bytes, and decodes the resulting bytes
#
proc checkit(v: bool) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check: bool
  discard decodeBool(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: int) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check: int
  discard decodeInteger(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: int64) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check: int
  discard decodeInteger(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: float, asDouble=false) =
  var res = encode(v, asDouble=asDouble)
  var numPadded: string = align(formatFloat(v, precision=6), padLength)
  var check: float
  discard decodeFloat(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & formatFloat(check, precision=6))

proc checkit(v: string) =
  var res = encode(v)
  var numPadded: string = align(v, padLength)
  var check: string = ""
  discard decodeString(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: openarray[int]) =
  var res = encode(v)
  var numPadded: string = align(showList(v), padLength)
  var check: seq[int]
  discard decodeIntList(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & showList(check))


proc checkit(v: openarray[float], asDouble=false) =
  var res = encode(v, asDouble)
  var numPadded: string = align(showList(v), padLength)
  var check: seq[float]
  discard decodeFloatList(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & showList(check))

######
# Here's where we'll actual drive the encode/decode routines.  We'll try to test 
# the "edge cases" as well as some more mundane values.
#
echo()
echo()
echo("Checking booleans...")
checkit(true)
checkit(false)
echo()

echo("Checking integers...")
checkit(0)
checkit(1)
checkit(-16)
checkit(47)
checkit(-2048)
checkit(-256)
checkit(2047)
checkit(-262144)
checkit(262143)
checkit(2621430)
checkit(2147483648)
echo()

echo("Checking floats...")
checkit(0.0)
checkit(1.0)
checkit(2.0)
checkit(-2.0)
checkit(-32768.0)
checkit(32767.0)
checkit(12.25)
checkit(1.2345,asDouble=false)
checkit(1.2345,asDouble=true)
echo()

echo("Checking strings...")
checkit("Hello world")
echo()

echo("Checking lists...")
checkit([1, 2, 3, 4, 5])
checkit([-1, -2, -3])
checkit([1.1, 2.2, 3.3], asDouble=false)

