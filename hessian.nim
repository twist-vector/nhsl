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
  unicode,
  times


include "private/utils"
include "private/encoders"
include "private/decoders"


when isMainModule:
  var t = getTime()
  echo "t: ", t
  var ts: string = encode(t, compact=false)
  echo "ts: ", ts
  var t2: Time
  var numBytes = decodeTime(ts, 0, t2)
  echo "t2: ", t2
