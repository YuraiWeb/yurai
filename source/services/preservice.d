/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.services.preservice;

import yurai.core.ihttprequest;
import yurai.core.ihttpresponse;
import yurai.services.middlewarestate;

public interface IPreMiddleware
{
  PreMiddlewareState handle(IHttpRequest request);
}
