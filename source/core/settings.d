/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.core.settings;

public:
version (YURAI_PREBUILD)
{
  static const bool Yurai_IsPreBuilding = true;
}
else
{
  static const bool Yurai_IsPreBuilding = false;
}

version (YURAI_DEBUG)
{
  static const bool Yurai_IsDebugging = true;
}
else
{
  static const bool Yurai_IsDebugging = false;
}

version (YURAI_VIBE_D)
{
  static const bool Yurai_UseVibed = true;
}
else
{
  static const bool Yurai_UseVibed = false;
}

version (YURAI_MYSQL)
{
  static const bool Yurai_UseMysql = true;

  static if (!(is(typeof((){import mysql;}))))
  {
    static assert(0, "Missing mysql dependency.");
  }
}
else
{
  static const bool Yurai_UseMysql = false;
}
