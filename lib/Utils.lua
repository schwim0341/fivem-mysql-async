---
-- Escape a value to avoid SQL injection
--
-- @param value
--
-- @return string
--
function MySQL.Utils.escape(value)
    return value
--    return MySQL.mysql.MySqlHelper.EscapeString(value)
end

---
-- Create a MySQL Command from a query string and its parameters
--
-- @param Query
-- @param Parameters
--
-- @return DbCommand
--
function MySQL.Utils.CreateCommand(Query, Parameters)
    local Command = MySQL:createConnection().CreateCommand()
    Command.CommandText = Query

    if type(Parameters) == "table" then
        for Param in pairs(Parameters) do
            Command.CommandText = string.gsub(Command.CommandText, Param, MySQL.Utils.escape(Parameters[Param]))
        end
    end

    return Command
end

---
-- Convert a result from MySQL to an object in lua
-- Take not that the reader will be closed after that
--
-- @param MySqlDataReader
--
-- @return object
--
function MySQL.Utils.ConvertResultToTable(MySqlDataReader)
    local result = {}

    while MySqlDataReader:Read() do
        local line = {}

        for i=0,MySqlDataReader.FieldCount-1 do
            line[MySqlDataReader.GetName(i)] = MySQL.Utils.ConvertFieldValue(MySqlDataReader, i);
        end

        result[#result+1] = line;
    end

    MySqlDataReader:Close()

    return result;
end

---
-- Convert a indexed field into a good value for lua
--
-- @param MysqlDataReader
-- @param index
--
-- @return mixed
--
function MySQL.Utils.ConvertFieldValue(MysqlDataReader, index)
    local type = tostring(MysqlDataReader:GetFieldType(index))

    if type == "System.DateTime" then
        return MysqlDataReader:GetDateTime(index)
    end

    if type == "System.Double" then
        return MysqlDataReader:GetDouble(index)
    end

    if type == "System.Int32" then
        return MysqlDataReader:GetInt32(index)
    end

    if type == "System.Int64" then
        return MysqlDataReader:GetInt64(index)
    end

    return MysqlDataReader:GetString(index)
end

---
-- Create a lua coroutine from a C# Task (System.Threading.Tasks.Task)
--
-- @param Task        Task that comes from C#
-- @param Transformer Delegate (function) to transform the result into another one
--
-- @return coroutine
--
function MySQL.Utils.CreateCoroutineFromTask(Task, Transformer)
    return coroutine.create(function()
        coroutine.yield(Transformer(Task.GetAwaiter().GetResult()))
    end)
end