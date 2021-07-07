/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.templates.templatedata;

import std.string : strip;
import std.array : split;

import yurai.templates.templatetype;

public interface ITemplateData
{
  @property TemplateType templateType();
}

public final class TemplateMeta : ITemplateData
{
  private:
  string _key;
  string[] _values;
  string _value;

  public:
  final:
  this(string key, string value)
  {
    auto values = value && value.strip.length ? value.strip.split(" ") : [];

    this(key, values);
  }

  this(string key, string[] values)
  {
    _key = key;

    if (values && values.length)
    {
      _values = values;
      _value = _values[0];
    }
  }

  @property
  {
    TemplateType templateType() { return TemplateType.meta; }

    string key() { return _key; }

    string[] values() { return _values; }

    string value() { return _value; }
  }
}

public final class TemplatePlaceholderValue : ITemplateData
{
  private:
  string _key;
  string _value;

  public:
  final:
  this(string key, string value)
  {
    _key = key;
    _value = value;
  }

  @property
  {
    TemplateType templateType() { return TemplateType.placeholderValue; }

    string key() { return _key; }

    string value() { return _value; }
  }
}

public final class TemplatePlaceholder : ITemplateData
{
  private:
  string _language;
  string _key;
  string _defaultText;

  public:
  final:
  this(string language, string key, string defaultText)
  {
    _language = language;
    _key = key;
    _defaultText = defaultText;
  }

  this(string key, string defaultText)
  {
    _key = key;
    _defaultText = defaultText;
  }

  this(string key)
  {
    _key = key;
  }

  @property
  {
    TemplateType templateType() { return TemplateType.placeholder; }

    string language() { return _language; }

    string key() { return _key; }

    string defaultText() { return _defaultText; }
  }
}

public final class TemplateMixinStatement : ITemplateData
{
  private:
  string _code;

  public:
  final:
  this(string code)
  {
    _code = code;
  }

  @property
  {
    TemplateType templateType() { return TemplateType.mixinStatement; }
  }
}

public final class TemplateMixinCodeBlock : ITemplateData
{
  private:
  string _code;

  public:
  final:
  this(string code)
  {
    _code = code;
  }

  @property
  {
    TemplateType templateType() { return TemplateType.mixinCodeBlock; }
  }
}

public final class TemplateMixinExpression : ITemplateData
{
  private:
  string _expression;

  public:
  final:
  this(string expression)
  {
    _expression = expression;
  }

  @property
  {
    TemplateType templateType() { return TemplateType.mixinExpression; }
  }
}

public final class TemplateMixinEscapeExpression : ITemplateData
{
  private:
  string _expression;

  public:
  final:
  this(string expression)
  {
    _expression = expression;
  }

  @property
  {
    TemplateType templateType() { return TemplateType.mixinEscapeExpression; }
  }
}

public final class TemplateContent : ITemplateData
{
  private:
  string _content;

  public:
  final:
  this(string content)
  {
    _content = content;
  }

  @property
  {
    TemplateType templateType() { return TemplateType.content; }
  }
}
