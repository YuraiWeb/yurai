/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.prebuilding.prebuildcontrollers;

void prebuildControllers()
{
  import std.file : write, dirEntries, SpanMode, readText;
  import std.algorithm : filter, startsWith, endsWith;
  import std.array : split, replace, join;
  import std.string : strip, format;

  string[] controllerModules = [];

  foreach (string name; dirEntries("controllers", SpanMode.depth).filter!(f => f.name.endsWith(".d")))
  {
    string content = readText(name);
    auto lines = content.replace("\r", "\n").split("\n");

    bool foundModuleStatement;

    foreach (line; lines)
    {
      if (!line || !line.length)
      {
        continue;
      }

      auto entries = line.split(";");

      foreach (ref entry; entries)
      {
        entry = entry.strip;

        if (entry.startsWith("module "))
        {
          auto moduleName = entry[7 .. $].strip;

          if (moduleName != "controllers")
          {
            controllerModules ~= "\"" ~ moduleName ~ "\"";
          }

          foundModuleStatement = true;
          break;
        }
      }

      if (foundModuleStatement)
      {
        break;
      }
    }
  }

  enum finalModule = `module yurai.prebuild.controllersmap;

  enum Yurai_ControllerModules = [
  %s
  ];`;

  auto moduleCode = finalModule.format(controllerModules.join(",\r\n"));

  write("prebuild/controllersmap.d", moduleCode);
}
