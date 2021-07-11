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
  string _contentType;

  public:
  final:
  this(string content, string contentType = null)
  {
    _content = content ? content : "";
    _contentType = contentType ? (contentType ~ "; charset=UTF-8") : "";

    if (!_contentType || !_contentType.length)
    {
      _contentType = "text/html; charset=UTF-8";
    }
  }

  this()
  {
    _content = null;
    _contentType = "text/html; charset=UTF-8";
  }

  @property
  {
    string content() { return _content; }

    string contentType() { return _contentType; }
  }
}
