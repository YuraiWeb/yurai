/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.services.basicerrorlogger;

import yurai.external.iserver;
import yurai.core.ihttprequest;
import yurai.core.ihttpresponse;
import yurai.services.middlewarestate;
import yurai.services.postservice;

public final class BasicErrorLogger : IPostMiddleware
{
  public:
  final:
  PostMiddlewareState handle(IHttpRequest request, IHttpResponse response, Exception error)
  {
    if (error)
    {
      import std.stdio : writeln;
      writeln(error);
    }

    return PostMiddlewareState.shouldContinue;
  }
}

IServer registerBasicErrorLogger(IServer server)
{
  return server.registerPostService(new BasicErrorLogger);
}
