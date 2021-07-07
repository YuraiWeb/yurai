/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.services.apicontrollers;

import yurai.external.iserver;
import yurai.core.ihttprequest;
import yurai.core.ihttpresponse;
import yurai.services.contentservice;
import yurai.services.middlewarestate;

private string removeControllerFromName(string s)
{
  import std.string : strip;
  import std.algorithm : endsWith;

  s = s.strip;

  if (s.endsWith("Controller"))
  {
    return s[0 .. "Controller".length];
  }

  return s;
}

public final class ApiControllerContentMiddleware : IContentMiddleware
{
  final:
  private this() {}

  public:
  ContentMiddlewareState handle(IHttpRequest request, IHttpResponse response)
  {
    import std.string : toLower, format;

    import yurai.prebuild.controllersmap;
    import yurai.controllers : Controller, ApiController, Status, HttpRoute;

    auto route = request.path && request.path.length && request.path[0].length ? request.path[0] : "/";

    switch (route.toLower)
    {
      static foreach (controllerModule; Yurai_ControllerModules)
      {{
        mixin("import moduleImport = " ~ controllerModule ~ ";");

        static foreach (symbolName; __traits(allMembers, moduleImport))
        {
          static if (__traits(compiles, { mixin("alias symbol = moduleImport." ~ symbolName ~ ";"); }))
          {
            mixin("alias symbol = moduleImport." ~ symbolName ~ ";");
            enum isClass = (is(symbol == class));

            static if (isClass)
            {
              static if (__traits(compiles, { static const _ = new symbol(null, null); }))
              {
                import std.traits : BaseClassesTuple;
                import std.meta : AliasSeq;
                import std.traits : hasUDA, getUDAs;

                static const isApiController = is(BaseClassesTuple!symbol == AliasSeq!(ApiController, Controller, Object));

                static if (isApiController)
                {
                  static if (hasUDA!(symbol, HttpRoute))
                  {
                    static const routeAttribute = getUDAs!(symbol, HttpRoute)[0];

                    static const routeName = routeAttribute.name.toLower;
                  }
                  else
                  {
                    static const routeName = symbolName.removeControllerFromName().toLower;
                  }

                  mixin(`
                    case "%s":
                      auto status = new symbol(request, response).handle();

                      if (status == Status.notFound) return ContentMiddlewareState.shouldContinue;
                      else return ContentMiddlewareState.exit;
                    `.format(routeName));
                }
              }
            }
          }
        }
      }}

      default: return ContentMiddlewareState.shouldContinue;
    }
  }
}

IServer registerApiControllers(IServer server)
{
  return server.registerContentService(new ApiControllerContentMiddleware);
}
