# yurai

![logo](https://yuraiweb.org/images/longlogo.png "Yurai Logo")

Yurai is a fast and modern full-stack web framework that can be used on-top of any other web frameworks such as vibe.d

It's entirely written in D and has no initial dependencies but recommended dependencies as of now are vibe.d [~>0.9.3] and mysql-native [~>3.0.2] (if you need mysql / mariadb support.)

*The framework is still in its initial development stage.*

Yurai is the successor to the Diamond MVC Web Framework and draws a lot of inspiration and features from Diamond.

Just like Diamond was inspired by ASP.NET MVC then Yurai is inspired heavily by ASP.NET Core.

Yurai for now will come with out of the box implementations and support for vibe.d and mysql but in the future other frameworks/libraries might have out of the box support too.

The current goal is to bring Yurai up to pair with Diamond and replace it entirely.

## Application Example

### source/main.d

```
module main;

import yurai;

void main()
{
  if (registerServers())
  {
    // Calling setupServer with "vibe.d" requires a vibe.d dependency and the version flag "YURAI_VIBE_D"
    auto server = setupServer("vibe.d", ["127.0.0.1"], 9898, "wwwroot");

    if (!server)
    {
      return;
    }

    // Features are registered as middleware services.
    // This makes it very flexible and easy to extend with features, as well remove unwanted features.

    server
      .registerViews() // Tells the server to support views
      .registerApiControllers() // Tells the server to support api controllers
      .registerNotFoundPage() // Tells the server to support a 404 page
      .registerBasicErrorLogger() // Tells the server to do basic error logging (to std out)
      .run(); // Runs the server
  }
}
```

### dub.json

```
{
  "name": "mywebsite",
  "targetType": "executable",
  "sourcePaths": [
    "source",
    "prebuild",
    "models",
    "controllers"
  ],
  "versions": [
    "YURAI_DEBUG",
    "YURAI_VIBE_D",
    "YURAI_MYSQL"
  ],
  "dependencies": {
    "yurai": "~>0.0.1",
    "vibe-d": "~>0.9.3",
    "mysql-native": "~>3.0.2"
  },
  "configurations": [{
    "name": "prebuild_yurai",
    "versions": [
      "YURAI_PREBUILD"
    ]
  }, {
    "name": "run_yurai",
    "versions": [
      "YURAI_RUN"
    ]
  }]
}
```

### Building / Running

The service must be built twice, one time to built the preprocessor, which then parses and creates the view / controller modules.

The second time to build the actual service that runs the website / webservice.

Example on building a Yurai project on Windows:

```
cls
dub build -a=x86_64 --config=prebuild_yurai
mywebsite
dub build -a=x86_64 --config=run_yurai
mywebsite
```

A similar approach should however work on any other platforms.

It's adviced to only build the project for 64 bit and it'll only be tested for 64 bit too.

32 bit (x86) won't have support and so don't expect it to work out of the box.

## View Example

The template syntax is similar to that of Diamond and its basically an updated and enhanced version of that.

### Layout (views/layout.dd)

```
@[name: layout]
@(website | My Website)
@(doctype)
<html>
<head>
  <title>@(title) | @(website)</title>
</head>
<body>
  @(view)
</body>
</html>
```

### View (views/home.dd)

```
@[layout: layout]
@[name: home]
@[route: /]
@[route: index]
@#(title | Home)

<p>Hello World</p>
```

### Html Output In The Browser

```
<!DOCTYPE html>
<html>
<head>
  <title>Home | My Website</title>
</head>
<body>
  <p>Hello World</p>
</body>
</html>
```

## Controller Examples

### View Controller

```
import yurai.controllers;

public final class HomeController(View) : WebController!View
{
  public:
  final:
  this(View view, IHttpRequest request, IHttpResponse response)
  {
    super(view, request, response);
  }

  @HttpDefault
  Status index()
  {
    // Do stuff with view, request, response ...
    // Returns Status.success to render the view ...
    return Status.success;
  }
}
```

### Api Controller

```
import yurai.controllers;

public class Foo
{
  public int x;
  public int y;
}

// The HttpRoute is not necessary.
// If it's not specified then the route becomes the name of the controller without the "Controller" part.
@HttpRoute("test")
public final class TestController : ApiController
{
  public:
  final:
  this(IHttpRequest request, IHttpResponse response)
  {
    super(request, response);
  }

  @HttpDefault
  Status index()
  {
    auto foo = new Foo;
    foo.x = 100;
    foo.y = 200;

    return json(foo);
  }
}
```

## ORM / Database Examples

### Database Model

```
@DbTable("tablename")
final class DbModel
{
  import std.datetime : DateTime;

  public:
  ulong id;
  string name;
  @DbCreateTime DateTime created;
  @DbTimestamp DateTime timestamp;
}
```

### Setup

```
// Requires mysql-native dependency and the version flag "YURAI_MYSQL"
import yurai.data.mapping.mysql;

auto service = new MysqlDataService("connectionString");
```

### Insert / Update

If the model's id doesn't evalute to truthy ex. if it's 0 then it will insert, otherwise it will update.

```
auto model = new DbModel;
model.name = "Name";
service.save(model);
```

### Insert / Update Many

Ditto regarding when save does what.

```
DbModel[] models = [];
foreach (_; 0 .. 10)
{
  auto model = new DbModel;
  model.name = "Name";
  models ~= model;
}

service.save(models);
```

### Select One

Parameters are query (where) and params.

```
auto params = new DbParam[1];
params[0] = cast(ulong)10;

auto model = service.selectSingle!(DbModel)("`id` = ?", params);
```

### Select Many

Ditto regarding parameters.

```
auto modelsRange = service.selectMany!(DbModel)(null, null);
```

**More information will come soon**