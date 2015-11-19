# Nim Hessian Serialization Library (NHSL)

The *NHSL* module is a partial implementation of the Hessian binary protocol.
Hessian is a compact binary protocol for cross-platform web services and
messaging.  It allows you to represent binary data (integers, floats, lists
objects, etc.) in a very compact form.  This allows storage or communication
to be small and fast.

For the Hessian spec, see [http://hessian.caucho.com/doc/hessian-serialization.html](http://hessian.caucho.com/doc/hessian-serialization.html)

This is only a partial implementation of the Hessian protocol.

## Supported
- boolean
- double
    - Compact: double zero
    - Compact: double one
    - Compact: double octet
    - Compact: double short
    - Compact: double float
- int
    - Compact: single octet integers
    - Compact: two octet integers
    - Compact: three octet integers
- list
    - Compact: fixed length list
- long
    - Compact: single octet longs
    - Compact: two octet longs
    - Compact: three octet longs
    - Compact: four octet longs
- string
    - Compact: short strings

## Unsupported:
- binary data
    - Compact: short binary
- date
    - Compact: date in minutes
- map
- null
- object
    - Compact: class definition
    - Compact: object instantiation
- ref
- type
    - Compact: type references
