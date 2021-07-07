/**
* Copyright © Yurai Web Framework 2021
* License: MIT (https://github.com/YuraiWeb/yurai/blob/main/LICENSE)
* Author: Jacob Jensen (bausshf)
*/
module yurai.data.mapping.mysql;

import std.variant : Variant;

public alias DbParam = Variant;

import yurai.core.settings;

public
{
  struct DbIgnore
  {
  }

  struct DbName
  {
    string name;
  }

  struct DbTimestamp
  {
  }

  struct DbCreateTime
  {
  }

  struct DbTable
  {
    string name;
  }
}

static if (Yurai_UseMysql)
{
  import std.algorithm : map;
  import std.string : format;
  import std.traits : hasUDA, getUDAs;
  import std.array : join;
  import std.conv : to;
  import std.datetime : Clock, SysTime, DateTime;

  private DateTime asDateTime(SysTime sysTime)
  {
    return DateTime(sysTime.year, sysTime.month, sysTime.day, sysTime.hour, sysTime.minute, sysTime.second);
  }

  import mysql;

  private static __gshared MySQLPool[string] _pools;
  private static shared globalPoolLock = new Object;

  MySQLPool getPool(string connectionString)
  {
    auto pool = _pools.get(connectionString, null);

    if (!pool)
    {
      synchronized (globalPoolLock)
      {
        pool = new MySQLPool(connectionString);

        _pools[connectionString] = pool;
      }

      return getPool(connectionString);
    }

    return pool;
  }

  private string[] generateSelect(T)()
  {
    string[] generatedColumns = [];
    auto generated = "";

    size_t index = 0;

    foreach (member; __traits(derivedMembers, T))
    {{
      static if (member != "__ctor")
      {
        mixin("static const isIgnore = hasUDA!(T.%s, DbIgnore);".format(member));
        mixin("static const hasName = hasUDA!(T.%s, DbName);".format(member));

        static if (!isIgnore)
        {
          mixin("static const memberType = (typeof(T." ~ member ~ ")).stringof;");

          static if (hasName)
          {
            mixin("enum dbNameAttribute = getUDAs!(T.%s, DbName)[0];".format(member));

            static const dbName = dbNameAttribute.name;
          }
          else
          {
            static const dbName = member;
          }

          generated ~= "model." ~ member ~ " = row[" ~ to!string(index) ~ "].get!(" ~ memberType ~ ");";
          index++;

          generatedColumns ~= "`" ~ dbName ~ "`";
        }
      }
    }}

    return [generatedColumns.join(", "), generated];
  }

  private string generateInsert(T)()
  {
    enum columnFormat = "`%s`";
    enum valueFormat = "?";
    enum paramFormat = "params[%s] = model.%s;";
    enum timestampFormat = "model.%s = currentTime;";

    string[] columns = [];
    string[] values = [];
    string[] params = [];
    string[] preCode = [];
    bool hasModelTimestamp = false;

    size_t index = 0;

    foreach (member; __traits(derivedMembers, T))
    {
      static if (member != "__ctor" && member != "id")
      {
        mixin("static const isIgnore = hasUDA!(T.%s, DbIgnore);".format(member));

        static if (!isIgnore)
        {
          mixin("static const hasName = hasUDA!(T.%s, DbName);".format(member));
          mixin("static const hasTimestamp = hasUDA!(T.%s, DbTimestamp) || hasUDA!(T.%s, DbCreateTime);".format(member, member));

          mixin("static const memberType = (typeof(T." ~ member ~ ")).stringof;");

          static if (hasName)
          {
            mixin("enum dbNameAttribute = getUDAs!(T.%s, DbName)[0];".format(member));

            static const dbName = dbNameAttribute.name;
          }
          else
          {
            static const dbName = member;
          }

          static if (hasTimestamp)
          {
            preCode ~= timestampFormat.format(member);
            hasModelTimestamp = true;
          }

          columns ~= columnFormat.format(dbName);
          values ~= valueFormat;
          params ~= paramFormat.format(index, member);
          index++;
        }
      }
    }

    if (hasModelTimestamp)
    {
      string[] timestampCode = [];

      timestampCode ~= "auto currentTime = Clock.currTime().asDateTime();";

      preCode = timestampCode ~ preCode;
    }

    auto generated = preCode.join("\r\n");
    generated ~= "auto values = \"%s\";\r\n".format(values.join(", "));
    generated ~= "auto columns = \"%s\";\r\n".format(columns.join(", "));
    generated ~= "auto params = new DbParam[" ~ to!string(params.length) ~ "];\r\n";
    generated ~= params.join("\r\n");

    return generated;
  }

  private string generateUpdate(T)()
  {
    enum columnFormat = "`%s` = ?";
    enum paramFormat = "params[%s] = model.%s;";
    enum timestampFormat = "model.%s = currentTime;";

    string[] columns = [];
    string[] params = [];
    string[] preCode = [];
    bool hasModelTimestamp = false;

    size_t index = 0;

    foreach (member; __traits(derivedMembers, T))
    {
      static if (member != "__ctor" && member != "id")
      {
        mixin("static const isIgnore = hasUDA!(T.%s, DbIgnore);".format(member));

        static if (!isIgnore)
        {
          mixin("static const hasName = hasUDA!(T.%s, DbName);".format(member));
          mixin("static const hasTimestamp = hasUDA!(T.%s, DbTimestamp);".format(member));

          mixin("static const memberType = (typeof(T." ~ member ~ ")).stringof;");

          static if (hasName)
          {
            mixin("enum dbNameAttribute = getUDAs!(T.%s, DbName)[0];".format(member));

            static const dbName = dbNameAttribute.name;
          }
          else
          {
            static const dbName = member;
          }

          static if (hasTimestamp)
          {
            preCode ~= timestampFormat.format(member);
            hasModelTimestamp = true;
          }

          columns ~= columnFormat.format(dbName);
          params ~= paramFormat.format(index, member);
          index++;
        }
      }
    }

    if (hasModelTimestamp)
    {
      string[] timestampCode = [];

      timestampCode ~= "auto currentTime = Clock.currTime().asDateTime();";

      preCode = timestampCode ~ preCode;
    }
    auto generated = preCode.join("\r\n");
    generated ~= "auto columns = \"%s\";\r\n".format(columns.join(", "));
    generated ~= "auto params = new DbParam[" ~ to!string(params.length + 1) ~ "];\r\n";
    generated ~= params.join("\r\n");

    return generated;
  }

  public final class MysqlDataService
  {
    private:
    string _connectionString;
    MySQLPool _pool;

    public:
    final:
    this(string connectionString)
    {
      _connectionString = connectionString;
      _pool = getPool(_connectionString);
    }

    void save(T)(T model, string table = null)
    {
      static if (hasUDA!(T, DbTable))
      {
        enum tableAttribute = getUDAs!(T, DbTable)[0];

        if (!table || !table.length)
        {
          table = tableAttribute.name;
        }
      }

      if (model.id)
      {
        update!T(model, table);
      }
      else
      {
        insert!T(model, table);
      }
    }

    private void insert(T)(T model, string table)
    {
      mixin(generateInsert!T);

      if (execute("INSERT INTO `%s` (%s) VALUES (%s);".format(table, columns, values), params) == 1)
      {
        auto id = executeScalar!(typeof(T.id))("SELECT LAST_INSERT_ID();", null);

        model.id = id;
      }
    }

    private void update(T)(T model, string table)
    {
      mixin(generateUpdate!T);

      params[params.length - 1] = model.id;

      execute("UPDATE `%s` SET %s WHERE `id` = ?".format(table, columns), params);
    }

    void remove(T)(T model, string table = null)
    {
      static if (hasUDA!(T, DbTable))
      {
        enum tableAttribute = getUDAs!(T, DbTable)[0];

        if (!table || !table.length)
        {
          table = tableAttribute.name;
        }
      }

      auto params = new DbParam[1];
      params[0] = model.id;

      execute("DELETE FROM `%s` WHERE `id` = ?".format(table), params);
    }

    void save(T)(T[] models, string table = null)
    {
      foreach (model; models)
      {
        save!T(model, table);
      }
    }

    void remove(T)(T[] models, string table = null)
    {
      foreach (model; models)
      {
        remove(model, table);
      }
    }

    ulong execute(string sql, DbParam[] params)
    {
      auto connection = _pool.lockConnection();
      auto prepared = connection.prepare(sql);

      prepared.setArgs(params ? params : new DbParam[0]);

      return connection.exec(prepared);
    }

    T executeScalar(T)(string sql, DbParam[] params)
    {
      auto connection = _pool.lockConnection();
      auto prepared = connection.prepare(sql);

      prepared.setArgs(params ? params : new DbParam[0]);

      auto result = connection.queryValue(prepared);

      if (result.isNull)
      {
        return T.init;
      }

      return result.get.coerce!T;
    }

    T selectSingle(T)(string query, DbParam[] params, string table = null)
    {
      enum generateResult = generateSelect!T;

      static if (hasUDA!(T, DbTable))
      {
        enum tableAttribute = getUDAs!(T, DbTable)[0];

        if (!table || !table.length)
        {
          table = tableAttribute.name;
        }
      }

      string sql = "SELECT " ~ generateResult[0] ~ " FROM `" ~ table ~ "`" ~ (query ? (" WHERE " ~ query) : "") ~ " LIMIT 1";

      auto connection = _pool.lockConnection();
      auto prepared = connection.prepare(sql);

      prepared.setArgs(params ? params : new DbParam[0]);

      auto result = connection.queryRow(prepared);

      if (result.isNull)
      {
        return T.init;
      }

      auto model = new T;

      mixin(generateResult[1]);

      return model;
    }

    auto selectMany(T)(string query, DbParam[] params, string table = null)
    {
      enum generateResult = generateSelect!T;

      static if (hasUDA!(T, DbTable))
      {
        enum tableAttribute = getUDAs!(T, DbTable)[0];

        if (!table || !table.length)
        {
          table = tableAttribute.name;
        }
      }

      string sql = "SELECT " ~ generateResult[0] ~ " FROM `" ~ table ~ "`" ~ (query ? (" WHERE " ~ query) : "");

      auto connection = _pool.lockConnection();
      auto prepared = connection.prepare(sql);

      prepared.setArgs(params ? params : new DbParam[0]);

      auto result = connection.query(prepared);

      return result.map!((row)
      {
        auto model = new T;

        mixin(generateResult[1]);

        return model;
      });
    }

    auto selectOffset(T)(string sql, DbParam[] params, int offset, int limit = 5000, string table = null, string sortColumn = "`id`", string sortType = null)
    {
      string orderSql = "";
      if (sortColumn !is null)
      {
        orderSql = " ORDER BY " ~ sortColumn;

        if (sortType !is null)
        {
          orderSql ~= " " ~ sortType;
        }
        else
        {
          orderSql ~= " ASC";
        }
      }

      return selectMany!T("%s%s LIMIT %s,%s".format(sql, orderSql, offset, limit), params, table);
    }
  }
}
else
{
  import std.range.interfaces : InputRange;

  public final class MysqlDataService
  {
    private:
    string _connectionString;

    public:
    final:
    this(string connectionString)
    {
      _connectionString = connectionString;
    }

    void insert(T)(T model, string table)
    {
      throw new Exception("...");
    }

    void update(T)(T model, string table)
    {
      throw new Exception("...");
    }

    void remove(T)(T model, string table)
    {
      throw new Exception("...");
    }

    void insert(T)(T[] models, string table)
    {
      throw new Exception("...");
    }

    void update(T)(T[] models, string table)
    {
      throw new Exception("...");
    }

    void remove(T)(T[] models, string table)
    {
      throw new Exception("...");
    }

    int execute(string sql, DbParam[] params)
    {
      throw new Exception("...");
    }

    T executeScalar(T)(string sql, DbParam[] params)
    {
      throw new Exception("...");
    }

    T selectSingle(T)(string sql, DbParam[] params)
    {
      throw new Exception("...");
    }

    InputRange!T selectMany(T)(string sql, DbParam[] params)
    {
      throw new Exception("...");
    }

    InputRange!T selectOffset(T)(string sql, DbParam[] params, int offset, int limit = 5000, string sortColumn = "`id`", string sortType = "ASC")
    {
      throw new Exception("...");
    }
  }
}
