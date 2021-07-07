/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.controllers.controlleraction;

import yurai.controllers.status;

public final class ControllerAction
{
  private:
  Status delegate() _delegate;

  Status function() _functionPointer;

  public:
  final:
  this(Status delegate() d)
  {
    _delegate = d;
  }


  this(Status function() f)
  {
    _functionPointer = f;
  }

  Status opCall()
  {
    if (_delegate)
    {
      return _delegate();
    }
    else if (_functionPointer)
    {
      return _functionPointer();
    }

    return Status.notFound;
  }
}
