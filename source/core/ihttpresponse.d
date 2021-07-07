/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.core.ihttpresponse;

public interface IHttpResponse
{
  @property
  {
    string contentType();
    void contentType(string value);
    bool hasRedirected();
    string redirectedUrl();
    bool hasBodyContent();
    int statusCode();
    void statusCode(int status);
  }

  void addHeader(string key, string value);
  void emptyBody();
  void writeBody(char[] value);
  void writeBody(string value);
  void appendBody(char[] value);
  void appendBody(string value);
  void appendBody(ubyte[] buffer);
  void flush();
  void redirect(string url, int status);
  void redirect(string url);
  void addCookie(string key, string value, long maxAge, string path);
  void removeCookie(string key, string path);
}
