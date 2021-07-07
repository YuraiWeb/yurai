/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.views.viewresult;

public final class ViewResult
{
  private:
  string _content;

  public:
  final:
  this(string content)
  {
    _content = content ? content : "";
  }

  this()
  {
    _content = null;
  }

  @property
  {
    string content() { return _content; }
  }
}
