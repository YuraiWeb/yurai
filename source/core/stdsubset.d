/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.core.stdsubset;

public
{
  import std.stdio : writeln, writefln;
  import std.file : write, exists, readText, isDir, isFile, isSymlink, rename, dirEntries, SpanMode, mkdir, rmdir, append, copy, read;
  import std.algorithm : filter, map, joiner, any, all, endsWith, startsWith, canFind, count, countUntil, group, fold, splitter, sort, reduce;
  import std.string : strip, stripLeft, stripRight, format, toLower, toUpper;
  import std.array : array, replace, join, split, appender;
  import std.datetime : Date, TimeOfDay, DateTime, Clock, SysTime, TimeZone, Duration, dur, weeks, days, hours, minutes, seconds, msecs, usecs, hnsecs, nsecs;
  import std.math : sin, cos, abs, fabs, sqrt, asin, acos, tan, atan, atan2, sinh, cosh, tanh, asinh, acosh, atanh, ceil, floor, round, lround, pow, powmod, log, log2, log10, fmod, modf, NaN, fdim, fmax, fmin, isClose, isFinite, isIdentical, isInfinity, isNaN, isNormal, isSubnormal;
  import std.uni : isWhite, isSymbol, isControl, isAlpha, isAlphaNum;
  import std.traits;
  import std.regex : regex, match, replace, matchAll, replaceAll, Regex;
  import std.conv : to;
}
