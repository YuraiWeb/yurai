/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.views.view;

import yurai.core;
import yurai.views.viewresult;
import yurai.external.iserver;

public abstract class View
{
  private:
  IHttpRequest _request;
  IHttpResponse _response;
  IServer _server;
  string _content;
  string[string] _placeholders;
  string _name;
  string _contentType;
  string _section;
  string[] _routes;

  protected:
  this(IHttpRequest request, IHttpResponse response, string[] routes = null)
  {
    this(null, request, response, null);
  }

  this(string name, IHttpRequest request, IHttpResponse response, string[] routes = null)
  {
    _name = name;

    _request = request;
    _response = response;

    _server = _request.server;

    _routes = routes;

    _placeholders["doctype"] = "<!doctype html>";
  }

  @property
  {
    IHttpRequest request() { return _request; }

    IHttpResponse response() { return _response; }

    IServer server() { return _server; }

    string name() { return _name; }

    string[] routes() { return _routes; }
  }

  void setContentType(string contentType)
  {
    _contentType = contentType;
  }

  ViewResult finalizeContent(string layout = null, bool processLayout = true)
  {
    if (layout && layout.length && processLayout)
    {
      import yurai.prebuild.viewsmap;

      auto layoutView = getView(layout, _request, _response);

      if (layoutView)
      {
        layoutView._name = _name;

        foreach (k,v; _placeholders)
        {
          layoutView.setPlaceholder(k, v);
        }

        layoutView.setPlaceholder("view", _content);
        return layoutView.generate(true);
      }
    }

    return new ViewResult(_content ? _content : "", _contentType);
  }

  void renderPartial(string name)
  {
    import yurai.prebuild.viewsmap;

    auto partialView = getView(name, _request, _response);

    if (partialView)
    {
      foreach (k,v; _placeholders)
      {
        partialView.setPlaceholder(k, v);
      }

      auto result = partialView.generateFinal(true);

      if (!result)
      {
        throw new Exception("Failed to render partial view.");
      }

      append(result.content ? result.content : "");
    }
  }

  void renderPartialModel(string name, T)(T model)
  {
    mixin("import yurai.prebuild.views : view_" ~ name ~ ";");
    import yurai.prebuild.viewsmap;

    mixin("auto partialView = cast(view_" ~ name ~ ")getView(name, _request, _response);");

    if (partialView)
    {
      foreach (k,v; _placeholders)
      {
        partialView.setPlaceholder(k, v);
      }

      auto result = partialView.generateModel(model);

      if (!result)
      {
        throw new Exception("Failed to render partial view.");
      }

      append(result.content ? result.content : "");
    }
  }

  void setPlaceholder(string key, string value)
  {
    _placeholders[key] = value;
  }

  string getPlaceholder(string key, string defaultValue = "")
  {
    return _placeholders.get(key, defaultValue ? defaultValue : "");
  }

  void appendPlaceholder(string key, string value)
  {
    auto content = getPlaceholder(key);

    content ~= value;

    setPlaceholder(key, content);
  }

  void setSection(string name)
  {
    _section = name == "*" ? null : ("section: " ~ name);
  }

  void escaped(T)(T data)
  {
    import std.conv : to;
    import yurai.security.html;

    auto s = to!string(data);

    s = escapeHtml(s);

    append(s);
  }

  void append(T)(T data)
  {
    import std.conv : to;

    import std.stdio;

    auto s = to!string(data);

    if (_section && _section != "*")
    {
      appendPlaceholder(_section, s);
    }
    else
    {
      _content ~= s;
    }
  }

  public:
  abstract ViewResult generate(bool processLayout);

  abstract ViewResult generateFinal(bool processLayout);
}
