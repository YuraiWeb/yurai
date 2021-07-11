/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.external.iserver;
import yurai.core.settings;
import yurai.services;

public interface IServer
{
  @property string name();
  void setup(string[] ipAddresses, ushort port, bool debugMode, string staticFilesFolder);
  void run();

  IServer registerPreService(IPreMiddleware middleware);
  IServer registerContentService(IContentMiddleware middleware);
  IServer registerPostService(IPostMiddleware middleware);

  @property IPreMiddleware[] preServices();
  @property IContentMiddleware[] contentServices();
  @property IPostMiddleware[] postServices();
  @property IMailService mailService();

  IServer registerMailService(IMailService mailService);
}

private IServer[string] _servers;

public:
void registerServer(IServer server)
{
  _servers[server.name] = server;
}

IServer setupServer(string name, string[] ipAddresses, ushort port, string staticFilesFolder)
{
  auto server = _servers.get(name, null);

  if (!server)
  {
    return null;
  }

  server.setup(ipAddresses, port, Yurai_IsDebugging, staticFilesFolder);

  return server;
}

private string[] _registeredViews;

void registerView(string file, string name, string route = null, string contentType = null, string additionalPreContent = null)
{
  import std.file : readText;
  import std.string : format;

  _registeredViews ~= "@[name: %s]\r\n%s%s%s".format(name, route ? "@[route: %s]\r\n".format(route) : "", contentType ? "@[content-type: %s]\r\n".format(contentType) : "", (additionalPreContent ? additionalPreContent : "") ~ readText(file));
}

bool registerServers()
{
  static if (!Yurai_IsPreBuilding)
  {
    static if (Yurai_UseVibed)
    {
      import yurai.external.servers.vibed;
      VibedServer.register();
    }
  }
  else
  {
    import yurai.prebuilding : preBuild;

    preBuild(_registeredViews);
  }

  return !Yurai_IsPreBuilding;
}
