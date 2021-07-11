/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.external.servers.vibed;

import yurai.core.settings;

static if (Yurai_UseVibed)
{
  import yurai.external;
  import yurai.core.ihttprequest;
  import yurai.core.ihttpresponse;
  import yurai.core.fileupload;
  import yurai.core.lazyload;
  import yurai.services;

  import vibe.d : HTTPFileServerSettings, HTTPServerRequestDelegateS, serveStaticFiles, HTTPServerSettings, URLRouter, listenHTTP, HTTPServerRequest, HTTPServerResponse, runApplication, Cookie, HTTPStatus;

  final class VibedServer : IServer
  {
    private:
    HTTPServerSettings _settings;
    URLRouter _router;
    IPreMiddleware[] _preMiddleware;
    IPostMiddleware[] _postMiddleware;
    IContentMiddleware[] _contentMiddleware;
    IMailService _mailService;

    this()
    {
      _preMiddleware = [];
      _postMiddleware = [];
      _contentMiddleware = [];
    }

    public:
    static void register()
    {
      registerServer(new VibedServer);
    }

    final:
    @property string name() { return "vibe.d"; }

    void setup(string[] ipAddresses, ushort port, bool debugMode, string staticFilesFolder)
    {
      _settings = new HTTPServerSettings;
      _settings.port = port;
      _settings.bindAddresses = ipAddresses;
      _settings.accessLogToConsole = debugMode;
      _settings.maxRequestSize = 4000000;
      _settings.maxRequestHeaderSize = 8192;

      _router = new URLRouter;

      import std.datetime : seconds;

      auto fsettings = new HTTPFileServerSettings;
    	fsettings.maxAge = 0.seconds();
    	_router.get("*", serveStaticFiles("./" ~ staticFilesFolder ~ "/", fsettings));

      _router.any("*", &handleHTTPListen);

      _router.rebuild();
    }

    void run()
    {
      listenHTTP(_settings, _router);

      runApplication();
    }

    IServer registerPreService(IPreMiddleware middleware)
    {
      _preMiddleware ~= middleware;
      return this;
    }

    IServer registerContentService(IContentMiddleware middleware)
    {
      _contentMiddleware ~= middleware;
      return this;
    }

    IServer registerPostService(IPostMiddleware middleware)
    {
      _postMiddleware ~= middleware;
      return this;
    }

    IServer registerMailService(IMailService mailService)
    {
      _mailService = mailService;

      return this;
    }

    @property
    {
      IPreMiddleware[] preServices()
      {
        return _preMiddleware;
      }

      IContentMiddleware[] contentServices()
      {
        return _contentMiddleware;
      }

      IPostMiddleware[] postServices()
      {
        return _postMiddleware;
      }

      IMailService mailService()
      {
        return _mailService;
      }
    }

    private:
    void handleHTTPListen(HTTPServerRequest request, HTTPServerResponse response)
    {
      import yurai.core.server;

      handleServer(this, new VibedHttpRequest(this, request), new VibedHttpResponse(this, response));
    }
  }

  final class VibedHttpRequest : IHttpRequest
  {
    private:
    HTTPServerRequest _request;
    string[] _path;
    string _ipAddress;
    string _body;
    string _method;
    LazyLoad!(string[string]) _headers;
    LazyLoad!(string[string]) _query;
    LazyLoad!(string[string]) _form;
    LazyLoad!(FileUpload[]) _files;
    IServer _server;

    final:
    this(IServer server, HTTPServerRequest request)
    {
      import std.array : split, array;
      import std.conv : to;
      import std.string : toLower, strip;
      import std.algorithm : map;

      _server = server;
      _request = request;

      auto requestPath = _request.requestPath.toString().strip;

      if (requestPath.length <= 1)
      {
        _path = ["/"];
      }
      else
      {
        if (requestPath[0] == '/')
        {
          requestPath = requestPath[1 .. $];
        }

        _path = requestPath.split("/").map!(r => r.toLower).array;
      }

      _method = to!string(_request.method);

      _headers = new LazyLoad!(string[string])({
        string[string] headers;

        if (_request.headers.length)
        {
          foreach (k,v; _request.headers.byKeyValue)
          {
            headers[k] = v;
          }
        }

        return headers;
      });

      _query = new LazyLoad!(string[string])({
        string[string] query;

        if (_request.query.length)
        {
          foreach (k,v; _request.query.byKeyValue)
          {
            query[k] = v;
          }
        }

        return query;
      });

      _form = new LazyLoad!(string[string])({
        string[string] form;

        if (_request.form.length)
        {
          foreach (k,v; _request.form.byKeyValue)
          {
            form[k] = v;
          }
        }

        return form;
      });

      _files = new LazyLoad!(FileUpload[])({
        FileUpload[] files;

        if (_request.files.length)
        {
          foreach (k,v; _request.files.byKeyValue)
          {
            files ~= FileUpload(k, v.tempPath.toString());
          }
        }

        return files;
      });
    }

    public:
    @property
    {
      string[] path()
      {
        return _path;
      }

      FileUpload[] files()
      {
        return _files.value;
      }

      string contentType()
      {
        return _request.contentType;
      }

      string ipAddress()
      {
        if (!_ipAddress)
        {
          auto ip = _request.headers.get("X-Real-IP", null);

          if (!ip || !ip.length)
          {
            ip = _request.headers.get("X-Forwarded-For", null);
          }

          _ipAddress = ip && ip.length ? ip : _request.clientAddress.toAddressString();
        }

        return _ipAddress;
      }

      string textBody()
      {
        if (!_body)
        {
          import vibe.stream.operations : readAllUTF8;

          _body = _request.bodyReader.readAllUTF8();
        }

        return _body;
      }

      string method()
      {
        return _method;
      }

      string host()
      {
        return _request.host;
      }

      IServer server() { return _server; }
    }

    string getHeader(string key)
    {
      return _headers.value.get(key, null);
    }

    bool hasHeader(string key)
    {
      return cast(bool)(key in _headers.value);
    }

    string getQuery(string key)
    {
      return _query.value.get(key, null);
    }

    bool hasQuery(string key)
    {
      return cast(bool)(key in _query.value);
    }

    string getForm(string key)
    {
      return _form.value.get(key, null);
    }

    bool hasForm(string key)
    {
      return cast(bool)(key in _form.value);
    }

    string getCookie(string key)
    {
      return _request.cookies[key];
    }

    bool hasCookie(string key)
    {
      return getCookie(key) !is null;
    }
  }

  final class VibedHttpResponse : IHttpResponse
  {
    private:
    HTTPServerResponse _response;
    bool _writeDisabled;
    bool _redirected;
    string _redirectedUrl;
    bool _shouldFlush;
    bool _hasBodyContent;
    IServer _server;

    final:
    this(IServer server, HTTPServerResponse response)
    {
      _server = server;
      _response = response;
      _writeDisabled = false;
    }

    public:
    @property
    {
      string contentType()
      {
        return getHeader("Content-Type");
      }

      void contentType(string value)
      {
        addHeader("Content-Type", value);
      }

      bool hasRedirected() { return _redirected; }

      string redirectedUrl() { return _redirectedUrl; }

      bool hasBodyContent() { return _hasBodyContent; }

      int statusCode() { return _response.statusCode; }
      void statusCode(int status)
      {
        _response.statusCode = status;
      }

      IServer server() { return _server; }
    }

    void addHeader(string key, string value)
    {
      _response.headers[key] = value;
    }

    string getHeader(string key)
    {
      return _response.headers[key];
    }

    void emptyBody()
    {
      if (_writeDisabled || _redirected) return;
      _writeDisabled = true;
      _shouldFlush = false;
      _hasBodyContent = true;

      _response.writeBody("\n");
    }

    void writeBody(char[] value)
    {
      writeBody(value.idup);
    }

    void writeBody(string value)
    {
      if (_writeDisabled || _redirected) return;
      _writeDisabled = true;
      _shouldFlush = false;
      _hasBodyContent = true;

      _response.writeBody(value);
    }

    void appendBody(char[] value)
    {
      appendBody(value.idup);
    }

    void appendBody(string value)
    {
      if (_writeDisabled || _redirected) return;

      _shouldFlush = true;
      _hasBodyContent = true;

      _response.bodyWriter.write(value);
    }

    void appendBody(ubyte[] buffer)
    {
      if (_writeDisabled || _redirected) return;

      _shouldFlush = true;
      _hasBodyContent = true;

      _response.bodyWriter.write(buffer);
    }

    void flush()
    {
      if (_shouldFlush)
      {
        _shouldFlush = false;
        _response.bodyWriter.flush();
      }
    }

    void redirect(string url, int status)
    {
      redirect(url);
    }

    void redirect(string url)
    {
      _redirected = true;

      _redirectedUrl = url;
      _response.redirect(url, HTTPStatus.found);
    }

    void addCookie(string key, string value, long maxAge, string path)
    {
      auto cookie = new Cookie;
      cookie.path = path ? path : "/";
      cookie.maxAge = maxAge > 0 ? maxAge : 1;
      cookie.setValue(value, Cookie.Encoding.none);

      _response.cookies[key] = cookie;
    }

    void removeCookie(string key, string path)
    {
      addCookie(key, null, 1, path);
    }
  }
}
