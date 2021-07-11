/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.core.ihttprequest;

import yurai.core.fileupload;
import yurai.external.iserver;

public interface IHttpRequest
{
  @property
  {
    string[] path();
    FileUpload[] files();
    string contentType();
    string ipAddress();
    string textBody();
    string method();
    string host();
    IServer server();
  }

  string getHeader(string key);
  bool hasHeader(string key);
  string getQuery(string key);
  bool hasQuery(string key);
  string getForm(string key);
  bool hasForm(string key);
  string getCookie(string key);
  bool hasCookie(string key);
}
