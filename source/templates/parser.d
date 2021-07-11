/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.templates.parser;

import yurai.templates.templatetype;
import yurai.templates.templatedata;

public final class Token
{
  public:
  final:
  TemplateType templateType;
  string content;

  this(TemplateType templateType)
  {
    this.templateType = templateType;

    content = "";
  }

  override string toString()
  {
    return content;
  }
}

public final class StringReader
{
  private:
  string _content;
  size_t _index;

  public:
  final:
  this(string content)
  {
    _content = content;
    _index = 0;
  }

  StringReader move()
  {
    _index++;

    return this;
  }

  StringReader back()
  {
    _index--;

    return this;
  }

  char peek(size_t amount)
  {
    auto index = _index + amount;

    return index < (_content.length - 1) ? _content[index] : '\0';
  }

  @property
  {
    bool has() { return _index < _content.length; }

    char last() { return _index > 0 ? _content[_index - 1] : '\0'; }

    char current() { return _content[_index]; }

    char next() { return peek(1); }
  }
}

public class Scope
{
  char scopeCharStart;
  char scopeCharEnd;
  size_t scopeCount;

  this(char scopeCharStart, char scopeCharEnd)
  {
    this.scopeCharStart = scopeCharStart;
    this.scopeCharEnd = scopeCharEnd;
    this.scopeCount = 0;
  }
}

public class ScopeStack
{
  Scope[] _stack;

  public:
  final:
  this()
  {
    _stack = [];
  }

  void push(Scope s)
  {
    _stack ~= s;
  }

  void pop()
  {
    if (_stack.length == 1)
    {
      _stack = [];
    }
    else if (_stack.length > 1)
    {
      _stack = _stack[0 .. $-1];
    }
  }

  @property
  {
    bool has() { return _stack.length > 0; }

    Scope currentScope() { return _stack[$-1]; }
  }
}

public:
Token[] parse(string content)
{
  import std.stdio : writeln, writefln;

  Token[] tokens = [];

  bool inComment = false;

  auto reader = new StringReader(content);

  auto scopeStack = new ScopeStack();

  auto contentToken = new Token(TemplateType.content);

  while (reader.has)
  {
    if (inComment)
    {
      if (reader.current == '@' && reader.last == '*')
      {
        inComment = false;
        continue;
      }
    }

    if (reader.current == '*' && reader.last == '@')
    {
      inComment = true;
    }
    else
    {
      if (reader.current == '@' && reader.last != '\\')
      {
        if (reader.next == '[')
        {
          if (contentToken && contentToken.content && contentToken.content.length)
          {
            tokens ~= contentToken;
            contentToken = new Token(TemplateType.content);
          }

          auto token = new Token(TemplateType.meta);
          // skip @ and [
          reader.move().move();

          // parse content as meta
          reader.basicDepthTagParsing('[', ']', token, tokens);
        }
        else if (reader.next == '#' && reader.peek(2) == '(')
        {
          if (contentToken && contentToken.content && contentToken.content.length)
          {
            tokens ~= contentToken;
            contentToken = new Token(TemplateType.content);
          }

          auto token = new Token(TemplateType.placeholderValue);
          // skip @ # and (
          reader.move().move().move();

          // parse content as placeholderValue
          reader.basicDepthTagParsing('(', ')', token, tokens);
        }
        else if (reader.next == '(')
        {
          if (contentToken && contentToken.content && contentToken.content.length)
          {
            tokens ~= contentToken;
            contentToken = new Token(TemplateType.content);
          }

          auto token = new Token(TemplateType.placeholder);
          // skip @ and (
          reader.move().move();

          // parse content as placeholder
          reader.basicDepthTagParsing('(', ')', token, tokens);
        }
        else if (reader.next == '{')
        {
          if (contentToken && contentToken.content && contentToken.content.length)
          {
            tokens ~= contentToken;
            contentToken = new Token(TemplateType.content);
          }

          auto token = new Token(TemplateType.mixinCodeBlock);
          // skip @ and {
          reader.move().move();

          // parse content as mixinCodeBlock
          reader.basicDepthTagParsing('{', '}', token, tokens);
        }
        else if (reader.next == '$' && reader.peek(2) == '=')
        {
          if (contentToken && contentToken.content && contentToken.content.length)
          {
            tokens ~= contentToken;
            contentToken = new Token(TemplateType.content);
          }

          auto token = new Token(TemplateType.mixinExpression);
          // skip @ $ and =
          reader.move().move().move();

          // parse content as mixinExpression
          reader.basicTagParsing(';', token, tokens);
        }
        else if (reader.next == '=')
        {
          if (contentToken && contentToken.content && contentToken.content.length)
          {
            tokens ~= contentToken;
            contentToken = new Token(TemplateType.content);
          }

          auto token = new Token(TemplateType.mixinEscapeExpression);
          // skip @ and =
          reader.move().move();

          // parse content as mixinEscapeExpression
          reader.basicTagParsing(';', token, tokens);
        }
        else if (reader.next == ':')
        {
          if (contentToken && contentToken.content && contentToken.content.length)
          {
            tokens ~= contentToken;
            contentToken = new Token(TemplateType.content);
          }

          auto token = new Token(TemplateType.mixinStatement);
          // skip @ and :
          reader.move().move();

          // parse content as mixinStatement
          auto scopeCharacter = reader.basicScopedTagParsing(token, tokens);

          if (scopeCharacter == '{')
          {
            scopeStack.push(new Scope(scopeCharacter, '}'));
          }
          else if (scopeCharacter == '(')
          {
            scopeStack.push(new Scope(scopeCharacter, ')'));
          }
          else if (scopeCharacter == '[')
          {
            scopeStack.push(new Scope(scopeCharacter, ']'));
          }
        }
        else if (reader.next == '<')
        {
          if (contentToken && contentToken.content && contentToken.content.length)
          {
            tokens ~= contentToken;
            contentToken = new Token(TemplateType.content);
          }

          auto token = new Token(TemplateType.partialView);
          // skip @ and <
          reader.move().move();

          // parse content as partialView
          reader.basicDepthTagParsing('<', '>', token, tokens);
        }
        else
        {
          contentToken.content ~= reader.current;
        }
      }
      else if (reader.current != '\\' || reader.next != '@')
      {
        if (scopeStack.has)
        {
          if (reader.current == scopeStack.currentScope.scopeCharStart)
          {
            scopeStack.currentScope.scopeCount++;
          }
          else if (reader.current == scopeStack.currentScope.scopeCharEnd)
          {
            if (scopeStack.currentScope.scopeCount == 0)
            {
              if (contentToken && contentToken.content && contentToken.content.length)
              {
                tokens ~= contentToken;
                contentToken = new Token(TemplateType.content);
              }

              auto token = new Token(TemplateType.mixinStatement);
              token.content ~= scopeStack.currentScope.scopeCharEnd;
              tokens ~= token;

              scopeStack.pop();
              reader.move();
              continue;
            }

            scopeStack.currentScope.scopeCount--;
          }
        }

        contentToken.content ~= reader.current;
      }
    }

    reader.move();
  }

  if (contentToken && contentToken.content && contentToken.content.length)
  {
    tokens ~= contentToken;
    contentToken = new Token(TemplateType.content);
  }

  return tokens;
}

private:
void basicDepthTagParsing(StringReader reader, char tagStart, char tagEnd, Token token, ref Token[] tokens)
{
  ptrdiff_t tagDepth = 0;

  while (reader.has)
  {
    if (reader.current == tagStart)
    {
      tagDepth++;
    }
    else if (reader.current == tagEnd)
    {
      if (tagDepth == 0)
      {
        tokens ~= token;
        break;
      }
      tagDepth--;
    }

    token.content ~= reader.current;

    reader.move();
  }
}

void basicTagParsing(StringReader reader, char tagEnd, Token token, ref Token[] tokens)
{
  while (reader.has)
  {
    if (reader.current == tagEnd)
    {
      tokens ~= token;
      break;
    }

    token.content ~= reader.current;

    reader.move();
  }
}

char basicScopedTagParsing(StringReader reader, Token token, ref Token[] tokens)
{
  while (reader.has)
  {
    if (reader.current == '\r' || reader.current == '\n')
    {
      auto scopeCharacter = reader.last;

      if (reader.current == '\r' && reader.next == '\n')
      {
        reader.move(); // skip the \n too ...
      }

      tokens ~= token;
      return scopeCharacter;
    }

    token.content ~= reader.current;

    reader.move();
  }

  return '\0';
}
