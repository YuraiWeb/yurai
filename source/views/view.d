/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.views.view;

import yurai.core;
import yurai.views.viewresult;

public abstract class View
{
  private:
  IHttpRequest _request;
  IHttpResponse _response;
  string _content;
  string[string] _placeholders;

  protected:
  this(IHttpRequest request, IHttpResponse response)
  {
    _request = request;
    _response = response;

    _placeholders["doctype"] = "<!doctype html>";
  }

  @property
  {
    IHttpRequest request() { return _request; }

    IHttpResponse response() { return _response; }
  }

  ViewResult finalizeContent(string layout = null)
  {
    if (layout && layout.length)
    {
      import yurai.prebuild.viewsmap;

      auto layoutView = getView(layout, _request, _response);

      if (layoutView)
      {
        foreach (k,v; _placeholders)
        {
          layoutView.setPlaceholder(k, v);
        }

        layoutView.setPlaceholder("view", _content);
        return layoutView.generate();
      }
    }

    return new ViewResult(_content ? _content : "");
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

      auto result = partialView.generateFinal();

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

    auto s = to!string(data);

    _content ~= s;
  }

  public:
  abstract ViewResult generate();

  abstract ViewResult generateFinal();
}
