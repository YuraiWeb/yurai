/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.core.lazyload;

final class LazyLoad(T)
{
  private T _value;
  private bool _hasLoaded;
  private T delegate() _initialization;

  public:
  final:
  this(T delegate() initialization)
  {
    _initialization = initialization;
  }

  this(T function() initialization)
  {
    this({ return initialization(); });
  }

  @property
  {
    T value()
    {
      if (!_hasLoaded)
      {
        _hasLoaded = true;

        if (_initialization)
        {
          _value = _initialization();
        }
      }

      return _value;
    }
  }
}
