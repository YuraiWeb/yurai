/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.core.strings;

import std.traits : isScalarType, isSomeString;

import std.string : representation;

template CharType(T)
if (isSomeString!T)
{
  static if (is(T == string))
  {
    alias CharType = char;
  }
  else static if (is(T == wstring))
  {
    alias CharType = wchar;
  }
  else static if (is(T == dstring))
  {
    alias CharType = dchar;
  }
  else
  {
    static assert(0, "Invalid string type");
  }
}

template CharBufferType(T)
if (isSomeString!T)
{
  static if (is(T == string))
  {
    alias CharBufferType = ubyte;
  }
  else static if (is(T == wstring))
  {
    alias CharBufferType = ushort;
  }
  else static if (is(T == dstring))
  {
    alias CharBufferType = uint;
  }
  else
  {
    static assert(0, "Invalid string type");
  }
}

T[] asStringRaw(T)(ubyte[] buf)
if (isScalarType!T)
{
    T[] vals = new T[buf.length / T.sizeof];

    foreach (offset; 0 .. vals.length)
    {
        vals[offset] = (*(cast(T*)(buf.ptr + (offset * T.sizeof))));
    }

    return vals;
}

ubyte[] asBytesRaw(T)(T[] vals)
if (isScalarType!T)
{
    ubyte[] buf = new ubyte[vals.length * T.sizeof];

    foreach (offset; 0 .. vals.length)
    {
        (*(cast(T*)(buf.ptr + (offset * T.sizeof)))) = vals[offset];
    }

    return buf;
}

S asString(S)(ubyte[] buf)
if (isSomeString!S)
{
  return (asStringRaw!(CharType!S)(buf)).dup;
}

ubyte[] asBytes(S)(S s)
if (isSomeString!S)
{
  return asBytesRaw!(CharBufferType!S)(s.representation.dup);
}
