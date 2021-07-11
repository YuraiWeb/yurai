/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.controllers.controller;

import yurai.core;
import yurai.controllers.status;
import yurai.controllers.controlleraction;
import yurai.controllers.controlleractionset;
import yurai.external.iserver;

///
public class Controller
{
  private:
  IHttpRequest _request;
  IHttpResponse _response;
  IServer _server;
  ControllerActionSet[string] _actions;

  void createMissingActionSet(string method)
  {
    import std.string : toLower;

    method = method.toLower;

    if (method !in _actions)
    {
      _actions[method] = new ControllerActionSet;
    }
  }

  public:
  this(IHttpRequest request, IHttpResponse response)
  {
    _request = request;
    _response = response;
    _server = _request.server;
  }

  final:
  @property
  {
    IHttpRequest request() { return _request; }

    IHttpResponse response() { return _response; }

    IServer server() { return _server; }
  }

  void mapMandatoryAction(string method, ControllerAction action)
  {
    import std.string : toLower;

    createMissingActionSet(method);

    _actions[method.toLower].mandatoryAction = action;
  }

  void mapDefaultAction(string method, ControllerAction action)
  {
    import std.string : toLower;

    createMissingActionSet(method);

    _actions[method.toLower].defaultAction = action;
  }

  void mapRoutedAction(string method, string name, ControllerAction action)
  {
    import std.string : toLower;

    createMissingActionSet(method);

    _actions[method.toLower].mapRoutedAction(name.toLower, action);
  }

  Status json(T)(T o, bool pretty = true)
  {
    auto s = serializeJson(o, pretty);

    return jsonString(s);
  }

  Status jsonString(string jsonString)
  {
    response.contentType = "application/json; charset=UTF-8";

    response.writeBody(jsonString);

    return Status.end;
  }

  Status handle()
  {
    string actionRoute;

    if (_request.path.length < 2)
    {
      actionRoute = "/";
    }
    else
    {
      actionRoute = _request.path[1];
    }

    if (!_actions)
    {
      return Status.notFound;
    }

    import std.string : toLower;

    auto methodActions = _actions.get(_request.method.toLower, null);

    if (!methodActions)
    {
      return Status.notFound;
    }

    if (methodActions.mandatoryAction)
    {
      ControllerAction mandatoryAction = methodActions.mandatoryAction;
      Status mandatoryResult = mandatoryAction();

      if (mandatoryResult != Status.success)
      {
        return mandatoryResult;
      }
    }

    if (actionRoute == "/" && methodActions.defaultAction)
    {
      ControllerAction defaultAction = methodActions.defaultAction;
      Status defaultResult = defaultAction();

      return defaultResult;
    }

    ControllerAction routedAction = methodActions.getRoutedAction(actionRoute);

    if (routedAction)
    {
      Status routedResult = routedAction();

      return routedResult;
    }

    return Status.notFound;
  }
}
