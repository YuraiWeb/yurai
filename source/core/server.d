/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.core.server;

import yurai.core.ihttprequest;
import yurai.core.ihttpresponse;
import yurai.external.iserver;
import yurai.services;

void handleServer(IServer server, IHttpRequest request, IHttpResponse response)
{
  import std.stdio : writeln, writefln;
  if (!server)
  {
    return;
  }

  bool fatalExit = false;

  Exception error = null;

  try
  {
    auto preMiddlewareServices = server.preServices;

    if (preMiddlewareServices)
    {
      bool handleMiddlewaresOnly = false;
      bool exitMiddleware = false;

      foreach (service; preMiddlewareServices)
      {
        if (exitMiddleware)
        {
          break;
        }

        auto state = service.handle(request);

        final switch (state)
        {
          case PreMiddlewareState.handleMiddlewaresOnly:
            handleMiddlewaresOnly = true;
            break;

          case PreMiddlewareState.exitFatal:
            fatalExit = true;
            throw new Exception("Fatal exit");

          case PreMiddlewareState.exit:
            exitMiddleware = true;
            break;

          case PreMiddlewareState.shouldContinue: break;
        }
      }

      if (handleMiddlewaresOnly || exitMiddleware)
      {
        return;
      }
    }

    auto contentMiddlewareServices = server.contentServices;

    if (contentMiddlewareServices)
    {
      bool exitMiddleware = false;

      foreach (service; contentMiddlewareServices)
      {
        if (exitMiddleware)
        {
          break;
        }

        auto state = service.handle(request, response);

        final switch (state)
        {
          case ContentMiddlewareState.exitFatal:
            fatalExit = true;
            throw new Exception("Fatal exit");

          case ContentMiddlewareState.exit:
            exitMiddleware = true;
            break;

          case ContentMiddlewareState.shouldContinue: break;
        }
      }
    }
  }
  catch (Exception e)
  {
      import std.stdio : writeln;

      writeln(e);

    if (fatalExit)
    {
      throw e;
    }
    else
    {
      error = e;
    }
  }
  catch (Throwable t)
  {
    fatalExit = true;

    import std.stdio : writeln;

    writeln(t);

    throw t;
  }
  finally
  {
    if (!fatalExit)
    {
      auto postMiddlewareServices = server.postServices;

      if (postMiddlewareServices)
      {
        bool exitMiddleware = false;

        foreach (service; postMiddlewareServices)
        {
          if (exitMiddleware)
          {
            break;
          }

          auto state = service.handle(request, response, error);

          final switch (state)
          {
            case PostMiddlewareState.exit:
              exitMiddleware = true;
              break;

            case PostMiddlewareState.shouldContinue: break;
          }
        }
      }
    }

    response.flush();
  }
}
