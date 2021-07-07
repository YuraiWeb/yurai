/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.controllers.controllerimplementations;

import std.string : strip, format;
import std.traits : fullyQualifiedName, hasUDA, getUDAs, Parameters, ParameterIdentifierTuple;
import std.array : split, array, join;
import std.conv : to;

import yurai.core;
import yurai.controllers.controller;
import yurai.controllers.controlleraction;
import yurai.controllers.controlleractionset;
import yurai.controllers.status;
import yurai.controllers.httpattributes;

enum memberHttpMethodFormat = q{
  static if (hasUDA!(%1$s.%2$s, HttpPost))
  {
    static const memberHttpMethod = "POST";
  }
  else static if (hasUDA!(%1$s.%2$s, HttpPut))
  {
    static const memberHttpMethod = "PUT";
  }
  else static if (hasUDA!(%1$s.%2$s, HttpDelete))
  {
    static const memberHttpMethod = "DELETE";
  }
  else static if (hasUDA!(%1$s.%2$s, HttpPatch))
  {
    static const memberHttpMethod = "PATCH";
  }
  else static if (hasUDA!(%1$s.%2$s, HttpOptions))
  {
    static const memberHttpMethod = "OPTIONS";
  }
  else static if (hasUDA!(%1$s.%2$s, HttpHead))
  {
    static const memberHttpMethod = "HEAD";
  }
  else static if (hasUDA!(%1$s.%2$s, HttpConnect))
  {
    static const memberHttpMethod = "CONNECT";
  }
  else static if (hasUDA!(%1$s.%2$s, HttpTrace))
  {
    static const memberHttpMethod = "TRACE";
  }
  else
  {
    static const memberHttpMethod = "GET";
  }
};

enum memberNameFormat = q{
  static if (hasUDA!(%1$s.%2$s, HttpRoute))
  {
    enum httpRoute = getUDAs!(%1$s.%2$s, HttpRoute)[0];

    static const memberActionName = httpRoute.name;
  }
  else
  {
    static const memberActionName = "%2$s";
  }
};

enum defaultMappingFormat = q{
  static if (hasUDA!(%1$s.%2$s, HttpDefault))
  {
    mapDefaultAction(memberHttpMethod, new ControllerAction(&controller.%2$s));
  }
};

enum mandatoryMappingFormat = q{
  static if (hasUDA!(%1$s.%2$s, HttpMandatory))
  {
    mapMandatoryAction(memberHttpMethod, new ControllerAction(&controller.%2$s));
  }
};

enum actionMappingFormat = q{
  static if (!(hasUDA!(%1$s.%2$s, HttpIgnore)))
  {
    enum parameterTypes_%2$s = Parameters!(controller.%2$s).stringof[1..$-1].split(", ");

    static if (parameterTypes_%2$s.length)
    {
      template isJsonObject(T)
      {
        static if (is(T == struct) || is(T == class))
        {
          enum isJsonObject = true;
        }
        else
        {
          enum isJsonObject = false;
        }
      }

      mixin("static const isJson = isJsonObject!" ~ parameterTypes_%2$s[0] ~ ";");

      static const isQuery = hasUDA!(%1$s.%2$s, HttpQuery);
      static const isForm = hasUDA!(%1$s.%2$s, HttpForm);
      static const isPath = hasUDA!(%1$s.%2$s, HttpPath);

      static if (isJson)
      {
        static if(parameterTypes_%2$s.length == 1)
        {
          mapRoutedAction(memberHttpMethod, memberActionName,
            new ControllerAction({
              mixin("auto jsonResult = deserializeJson!("~ parameterTypes_%2$s[0] ~")(request.textBody);");
              return controller.%2$s(jsonResult);
            }));
        }
        else
        {
          static assert(0, "Can only map a single json object.");
        }
      }
      else static if (isQuery || isForm || isPath)
      {
        enum parameterNames_%2$s = [ParameterIdentifierTuple!(controller.%2$s)];

        mapRoutedAction(memberHttpMethod, memberActionName,
          new ControllerAction({
            static foreach (i; 0 .. parameterNames_%2$s.length)
            {
              static if (isQuery)
              {
                mixin("auto " ~ parameterNames_%2$s[i] ~ " = to!(" ~ (parameterTypes_%2$s[i]) ~ ")(request.getQuery(\"" ~ parameterNames_%2$s[i] ~ "\"));");
              }
              else static if (isForm)
              {
                mixin("auto " ~ parameterNames_%2$s[i] ~ " = to!(" ~ (parameterTypes_%2$s[i]) ~ ")(request.getForm(\"" ~ parameterNames_%2$s[i] ~ "\"));");
              }
              else static if (isPath)
              {
                mixin("auto " ~ parameterNames_%2$s[i] ~ " = to!(" ~ (parameterTypes_%2$s[i]) ~ ")(request.path[" ~ to!string(i + 2) ~ "]);");
              }
            }

            mixin("return controller.%2$s(" ~ (parameterNames_%2$s.join(",")) ~ ");");
          }));
      }
      else
      {
        static assert(0, "Unable to determine a mapping path for the action.");
      }
    }
    else
    {
      mapRoutedAction(memberHttpMethod, memberActionName,
        new ControllerAction(&controller.%2$s));
    }
  }
};

public class WebController(TView) : Controller
{
  private:
  TView _view;

  public:
  this(this TController)(TView view, IHttpRequest request, IHttpResponse response)
  {
    super(request, response);

    _view = view;

    mixin("import yurai.prebuild.views : " ~ TController.stringof.split("!")[1][1 .. $-1] ~ ";");

    import controllers;
    import models;

    auto controller = cast(TController)this;

    foreach (member; __traits(derivedMembers, TController))
    {{
      static if (member != "__ctor")
      {
        mixin(memberNameFormat.format(TController.stringof, member));
        mixin(memberHttpMethodFormat.format(TController.stringof, member));

        mixin(defaultMappingFormat.format(TController.stringof, member));
        mixin(mandatoryMappingFormat.format(TController.stringof, member));
        mixin(actionMappingFormat.format(TController.stringof, member));
      }
    }}
  }

  @property
  {
    TView view() { return _view; }
  }
}

public class ApiController : Controller
{
  public:
  this(this TController)(IHttpRequest request, IHttpResponse response)
  {
    super(request, response);

    import controllers;
    import models;

    auto controller = cast(TController)this;

    foreach (member; __traits(derivedMembers, TController))
    {{
      static if (member != "__ctor")
      {
        mixin(memberNameFormat.format(TController.stringof, member));
        mixin(memberHttpMethodFormat.format(TController.stringof, member));

        mixin(defaultMappingFormat.format(TController.stringof, member));
        mixin(mandatoryMappingFormat.format(TController.stringof, member));
        mixin(actionMappingFormat.format(TController.stringof, member));
      }
    }}
  }
}
