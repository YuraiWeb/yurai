/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.core.conv;

import std.traits : isSomeString;

// TODO: Better implementation ...
bool tryParse(From,To)(From fromValue, out To toValue)
{
  import std.conv : to, ConvException;

  try
  {
    toValue = fromValue.to!To;
    return true;
  }
  catch (ConvException e)
  {
    toValue = To.init;
    return false;
  }
}

bool canParseNumeric(S)(S s)
if (isSomeString!S)
{
  import std.string : isNumeric;
  import std.conv : to, ConvException;

  return s && s.length && ((s.length >= 2 && s[0] == '-' && s[1].to!(string).isNumeric) || (s.length >= 2 && s[0] == '+' && s[1].to!(string).isNumeric) || s[0].to!(string).isNumeric) && s.isNumeric;
}
