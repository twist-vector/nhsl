import strutils

proc i2h(x: int): string =
  result = "0x" & toHex(x,2)

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
