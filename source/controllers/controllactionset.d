/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.controllers.controlleractionset;

import yurai.controllers.controlleraction;

public final class ControllerActionSet
{
  private:
  ControllerAction _mandatoryAction;
  ControllerAction _defaultAction;
  ControllerAction[string] _routedActions;

  public:
  @property
  {
    ControllerAction mandatoryAction() { return _mandatoryAction; }

    void mandatoryAction(ControllerAction action)
    {
      _mandatoryAction = action;
    }

    ControllerAction defaultAction() { return _defaultAction; }

    void defaultAction(ControllerAction action)
    {
      _defaultAction = action;
    }
  }

  void mapRoutedAction(string name, ControllerAction action)
  {
    import std.string : toLower;

    _routedActions[name.toLower] = action;
  }

  ControllerAction getRoutedAction(string name)
  {
    import std.string : toLower;

    if (!_routedActions)
    {
      return null;
    }

    return _routedActions.get(name.toLower, null);
  }
}
