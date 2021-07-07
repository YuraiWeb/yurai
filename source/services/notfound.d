/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.services.notfound;

import yurai.external.iserver;
import yurai.core.ihttprequest;
import yurai.core.ihttpresponse;
import yurai.services.contentservice;
import yurai.services.middlewarestate;

public final class NotFoundContentMiddleware : IContentMiddleware
{
  final:
  private this() {}

  public:
  ContentMiddlewareState handle(IHttpRequest request, IHttpResponse response)
  {
    import yurai.prebuild.viewsmap : getView;

    auto notFoundView = getView("404", request, response);

    if (notFoundView is null)
    {
      return ContentMiddlewareState.shouldContinue;
    }

    auto result = notFoundView.generate();
    auto content = result && result.content && result.content.length ? result.content : "";

    response.contentType = "text/html; charset=UTF-8";
    response.statusCode = 404;
    response.writeBody(content);

    return ContentMiddlewareState.exit;
  }
}

IServer registerNotFoundPage(IServer server)
{
  return server.registerContentService(new NotFoundContentMiddleware);
}
