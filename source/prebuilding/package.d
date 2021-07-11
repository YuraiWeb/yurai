/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.prebuilding;

public
{
  import yurai.prebuilding.prebuildcontrollers;
  import yurai.prebuilding.prebuildviews;
}

void preBuild(string[] registeredViews)
{
  prebuildControllers();
  prebuildViews(registeredViews);
}
