/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.services.views;

import yurai.external.iserver;
import yurai.core.ihttprequest;
import yurai.core.ihttpresponse;
import yurai.services.contentservice;
import yurai.services.middlewarestate;

public final class ViewsContentMiddleware : IContentMiddleware
{
  final:
  private this() {}

  public:
  ContentMiddlewareState handle(IHttpRequest request, IHttpResponse response)
  {
    import std.array : join;

    import yurai.prebuild.viewsmap : processView;

    auto route = request.path && request.path.length && request.path[0].length ? request.path.join("/") : "/";

    auto result = processView(route, request, response);

    if (result is null)
    {
      return ContentMiddlewareState.shouldContinue;
    }

    if (result.content !is null)
    {
      response.contentType = result.contentType;

      response.writeBody(result.content);
    }

    return ContentMiddlewareState.exit;
  }
}

IServer registerViews(IServer server)
{
  return server.registerContentService(new ViewsContentMiddleware);
}
