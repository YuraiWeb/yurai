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

bool registerServers()
{
  static if (!Yurai_IsPreBuilding)
  {
    static if (Yurai_UseVibed)
    {
      import yurai.external.vibed;
      VibedServer.register();
    }
  }
  else
  {
    import yurai.prebuilding : preBuild;

    preBuild();
  }

  return !Yurai_IsPreBuilding;
}
