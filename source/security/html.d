/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.security.html;

string escapeHtml(string html)
{
  import std.string : format;
  import std.conv : to;

  if (!html || !html.length)
  {
    return html;
  }

  string result = "";

  foreach (c; html)
  {
    switch (c)
    {
      case '<':
      {
        result ~= "&lt;";
        break;
      }

      case '>':
      {
        result ~= "&gt;";
        break;
      }

      case '"':
      {
        result ~= "&quot;";
        break;
      }

      case '\'':
      {
        result ~= "&#39;";
        break;
      }

      case '&':
      {
        result ~= "&amp;";
        break;
      }

      case '/':
      {
        result ~= "&#47;";
        break;
      }

      default:
      {
        if (c < ' ' && c != '\r' && c != '\n' && c != '\t')
        {
          result ~= format("&#%d;", c);
        }
        else
        {
          result ~= to!string(c);
        }
      }
    }
  }

  return result;
}
