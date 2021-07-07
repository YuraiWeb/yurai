/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.services.middlewarestate;

public enum PreMiddlewareState
{
  shouldContinue,
  handleMiddlewaresOnly,
  exitFatal,
  exit
}

public enum PostMiddlewareState
{
  shouldContinue,
  exit
}

public enum ContentMiddlewareState
{
  shouldContinue,
  exit,
  exitFatal
}
