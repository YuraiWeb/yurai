/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.prebuilding.prebuildviews;

import yurai.templates;

void prebuildViews(string[] registeredViews)
{
  import std.file : dirEntries, SpanMode, readText, remove;
  import std.algorithm : filter, endsWith;

  ViewInformation[] viewInformations;

  foreach (string name; dirEntries("prebuild/views", SpanMode.depth).filter!(f => f.name.endsWith(".d")))
  {
    remove(name);
  }

  foreach (string name; dirEntries("views", SpanMode.depth).filter!(f => f.name.endsWith(".dd")))
  {
    string content = readText(name);

    auto viewInformation = parseView(content);

    if (viewInformation.name && viewInformation.name.length)
    {
      viewInformations ~= viewInformation;
    }
  }

  foreach (content; registeredViews)
  {
    auto viewInformation = parseView(content);

    if (viewInformation.name && viewInformation.name.length)
    {
      viewInformations ~= viewInformation;
    }
  }

  prebuildPackage(viewInformations);
  prebuildViewClasses(viewInformations);
  prebuildViewsMap(viewInformations);
}

private:
ViewInformation parseView(string content)
{
  auto viewInformation = new ViewInformation;
  auto tokens = parse(content);

  if (tokens && tokens.length)
  {
    foreach (token; tokens)
    {
      if (!token || !token.content || !token.content.length)
      {
        continue;
      }

      if (token.templateType != TemplateType.content)
      {
        viewInformation.lastWasContent = false;
      }

      switch (token.templateType)
      {
        case TemplateType.content:
          parseContent(token, viewInformation);
          viewInformation.lastWasContent = true;
          break;

        case TemplateType.meta:
          parseMeta(token, viewInformation);
          break;

        case TemplateType.placeholderValue:
          parsePlaceholderValue(token, viewInformation);
          break;

        case TemplateType.placeholder:
          parsePlaceholder(token, viewInformation);
          viewInformation.lastWasContent = true;
          break;

        case TemplateType.mixinStatement:
          parseMixinStatement(token, viewInformation);
          break;

        case TemplateType.mixinCodeBlock:
          parseMixinCodeBlock(token, viewInformation);
          break;

        case TemplateType.mixinExpression:
          parseMixinExpression(token, viewInformation);
          break;

        case TemplateType.mixinEscapeExpression:
          parseMixinEscapedExpression(token, viewInformation);
          break;

        case TemplateType.partialView:
          parsePartialView(token, viewInformation);
          viewInformation.lastWasContent = true;
          break;

        default: break;
      }
    }
  }

  return viewInformation;
}

class ViewInformation
{
  string name;
  string layout;
  string model;
  string controller;
  string[] routes;
  string[] executePreContent;
  string[] executeContent;
  bool lastWasContent;
  string contentType;

  this()
  {
    routes = [];
    executePreContent = [];
    executeContent = [];
  }
}

void parseContent(Token token, ViewInformation view)
{
  import std.string : format,strip;
  import std.array : replace;

  if ((!view.executeContent.length || !view.lastWasContent) && !token.content.strip.length)
  {
    return;
  }

  view.executeContent ~= "append(`%s`);".format(token.content.replace("`", "&#96;"));
}

void parseMeta(Token token, ViewInformation view)
{
  import std.string : strip, format;
  import std.array : split;

  auto pair = token.content.split(":");

  if (!pair || pair.length != 2)
  {
    return;
  }

  auto value = pair[1].strip;

  switch (pair[0].strip)
  {
    case "layout":
      view.layout = value;
      break;

    case "name":
      view.name = value;
      break;

    case "model":
      view.model = value;
      break;

    case "controller":
      view.controller = value;
      break;

    case "route":
      view.routes ~= value;
      break;

    case "content-type":
      view.contentType = value;
      break;

    case "section":
      view.executeContent ~= "setSection(`%s`);".format(value);
      break;

    default: break;
  }
}

void parsePlaceholderValue(Token token, ViewInformation view)
{
  import std.string : format, strip;
  import std.array : split;

  auto pair = token.content.split("|");

  if (!pair || pair.length != 2)
  {
    return;
  }

  auto key = pair[0].strip;
  auto value = pair[1].strip;

  view.executePreContent ~= "setPlaceholder(`%s`, `%s`);".format(key, value);
}

void parsePlaceholder(Token token, ViewInformation view)
{
  import std.string : format, strip;
  import std.array : split;

  auto entries = token.content.split("|");

  if (!entries || !entries.length || entries.length > 2)
  {
    return;
  }

  string key = null;
  if (entries.length == 1)
  {
    key = entries[0].strip;

    view.executeContent ~= "append(getPlaceholder(`%s`));".format(key);
  }

  if (entries.length == 2)
  {
    auto defaultText = entries[1].strip;

    view.executeContent ~= "append(getPlaceholder(`%s`, `%s`));".format(key, defaultText);
  }
}

void parseMixinStatement(Token token, ViewInformation view)
{
  import std.string : format;

  view.executeContent ~= token.content;
}

void parseMixinCodeBlock(Token token, ViewInformation view)
{
  import std.string : format;

  view.executeContent ~= token.content;
}

void parseMixinExpression(Token token, ViewInformation view)
{
  import std.string : format;

  view.executeContent ~= "append(%s);".format(token.content);
}

void parseMixinEscapedExpression(Token token, ViewInformation view)
{
  import std.string : format;

  view.executeContent ~= "escaped(%s);".format(token.content);
}

void parsePartialView(Token token, ViewInformation view)
{
  import std.string : strip, format;
  import std.array : split;

  auto pair = token.content.split(":");

  if (!pair || pair.length < 1 || pair.length > 2)
  {
    return;
  }

  auto viewName = pair[0].strip;

  if (pair.length == 2)
  {
    auto viewModel = pair[1].strip;

    view.executeContent ~= "renderPartialModel!`%s`(%s);".format(viewName, viewModel);
  }
  else
  {
    view.executeContent ~= "renderPartial(`%s`);".format(viewName);
  }
}

void prebuildPackage(ViewInformation[] viewInformations)
{
  import std.string : format;
  import std.file : write;
  import std.array : join;

  enum finalModule = `module yurai.prebuild.views;

  public
  {
%s
  }
`;

  enum importFormat = "    import yurai.prebuild.views.view_%s;";

  string[] importList = [];

  foreach (viewInformation; viewInformations)
  {
    importList ~= importFormat.format(viewInformation.name);
  }

  write("prebuild/views/package.d", finalModule.format(importList.join("\r\n")));
}

void prebuildViewClasses(ViewInformation[] viewInformations)
{
  import std.string : format;
  import std.array : join, array;
  import std.algorithm : map;
  import std.file : write;

  enum finalModule = `module yurai.prebuild.views.view_%s;

import yurai;

import models;

public final class view_%s : View
{
  public:
  %s
  final:
  this(IHttpRequest request, IHttpResponse response)
  {
    super("%s", request,response, [%s]);
  }

  override ViewResult generate(bool processLayout)
  {
    %s

    return generateFinal(processLayout);
  }
  ViewResult generateModel(%s)
  {
    %s
    return generateFinal(true);
  }
  override ViewResult generateFinal(bool processLayout)
  {
    %s
    %s

    %s

    return finalizeContent(%s);
  }
}
`;

  foreach (view; viewInformations)
  {
    string controllerCall = "";

    if (view.controller)
    {
      controllerCall ~= "import controllers;\r\n";
      controllerCall ~= "auto controller = new " ~ view.controller ~ "!(view_" ~ view.name ~ ")(this, request, response);\r\n";
      controllerCall ~= "auto status = controller.handle();\r\n";
      controllerCall ~= "if (status == Status.end) return new ViewResult();\r\n";
      controllerCall ~= "if (status == Status.notFound) return null;";
    }

    string moduleCode = finalModule
      .format(
        view.name,
        view.name,
        view.model && view.model.length ? (view.model ~ " model;") : "",
        view.name,
        view.routes ? view.routes.map!(r => "`%s`".format(r)).array.join(",") : "",
        controllerCall,
        view.model && view.model.length ? (view.model ~ " model") : "",
        view.model && view.model.length ? ("this.model = model;") : "",
        view.executePreContent.join("\r\n"),
        view.executeContent.join("\r\n"),
        view.contentType ? "setContentType(\"%s\");".format(view.contentType) : "",
        view.layout && view.layout.length ? ("`" ~ view.layout ~ "`,processLayout") : "null,processLayout");

    write("prebuild/views/" ~ view.name ~ ".d", moduleCode);
  }
}

void prebuildViewsMap(ViewInformation[] viewInformations)
{
  import std.string : format;
  import std.array : join, array;
  import std.file : write;
  import std.algorithm : map;

  enum finalModule = `module yurai.prebuild.viewsmap;

  import yurai.prebuild.views;
  import yurai.views;
  import yurai.core;

  string[] getAllRoutes()
  {
    return [%s];
  }

  View getView(string name, IHttpRequest request, IHttpResponse response)
  {
    switch (name)
    {
%s

      default:
        return null;
    }
  }

  ViewResult processView(string route, IHttpRequest request, IHttpResponse response, bool processLayout = true)
  {
    switch (route)
    {
%s

      default:
        return null;
    }
  }
`;
  enum viewGetFormat = `      case "%s":
        return new view_%s(request, response);`;
  enum viewProcessCaseFormat = `      case "%s":`;
  enum viewProcessFormat = `%s
        return new view_%s(request, response).generate(processLayout);`;

  string[] viewGet = [];
  string[] viewProcessing = [];
  string[] viewRoutes = [];

  foreach (view; viewInformations)
  {
    viewGet ~= viewGetFormat.format(view.name, view.name);

    if (view.routes && view.routes.length)
    {
      viewRoutes ~= view.routes;

      string cases = view.routes.map!(r => viewProcessCaseFormat.format(r)).array.join("\r\n");

      viewProcessing ~= viewProcessFormat.format(cases, view.name);
    }
  }

  auto finalViewRoutes = viewRoutes.map!(r => "`%s`".format(r)).array.join(",");

  write("prebuild/viewsmap.d", finalModule.format(finalViewRoutes, viewGet.join("\r\n"), viewProcessing.join("\r\n")));
}
