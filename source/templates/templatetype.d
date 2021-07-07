/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.templates.templatetype;

public enum TemplateType
{
  content, // Anything that doesn't match a template type
  meta, // @[key: value] - can be settings or instructions (something that tells the generator to do something ex. @[partial: viewname] will render a partial view - equivalent to @:render("viewname");)
  placeholderValue, // @#(key | value) -- equivalent to @:addPlaceholder("key", "value");
  placeholder, // @(key) @(key | default text)
  mixinStatement, // @:statement\n @:statement {\n} @statement: [\n] @:statement: (\n) -- should match nested blocks ... The first block should also be able to be on the next line unless the statement has a ;
  mixinCodeBlock, // @{\n}
  mixinExpression, // @$=expression;
  mixinEscapeExpression, // @=expression;
  partialView, // @<name> | @<name: modelParameter>
  comment, // @* ... *@
  escape // \@
}
