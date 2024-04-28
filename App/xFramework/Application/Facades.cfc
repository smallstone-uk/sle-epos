component
{
    /**
     * Returns a new route object.
     *
     * @return route
     */
    public any function route(string controller = '', string method = '')
    {
        return new App.Framework.Route(controller, method);
    }

    /**
     * Returns a new view object.
     *
     * @return view
     */
    public any function view(required string name, struct args = {})
    {
        return new App.Framework.View(name, args);
    }

    /**
     * Returns a new query builder object.
     *
     * @return queryBuilder
     */
    public any function queryBuilder(string datasource = "")
    {
        return new App.Framework.QueryBuilder(datasource);
    }

    /**
     * Returns a new schema object.
     *
     * @return schema
     */
    public any function schema(required string table, string datasource = "")
    {
        return new App.Framework.Schema(table, datasource);
    }

    /**
     * Returns a new validate object.
     *
     * @return validate
     */
    public any function validate(required struct data, required struct rules)
    {
        return new App.Framework.Validate(data, rules);
    }

    /**
     * Returns the user object in the session.
     *
     * @return user
     */
    public any function user()
    {
        return session.user;
    }

    /**
     * Gets a full URL with the given path.
     *
     * @return string
     */
    public string function getUrl(string uri = '')
    {
        var https = (cgi.https == 'off') ? 'http' : 'https';
        return '#https#://#cgi.server_name#/#uri#';
    }

    /**
     * Gets the datasource.
     *
     * @return string
     */
    public string function getDatasource(boolean migration = false)
    {
        if (migration) {
            return application.mvc.migrationDatasource;
        }

        return application.mvc.datasource;
    }

    /**
     * Gets the base directory path (wwwroot).
     *
     * @return string
     */
    public string function getBaseDir(string path = '')
    {
        var baseDir = application.mvc.baseDirectory;

        if (arrayContains(['/', '\'], right(baseDir, 1))) {
            baseDir = left(baseDir, len(baseDir) - 1);
        }

        return '#baseDir#\#path#';
    }

    /**
     * Gets the data directory path.
     *
     * @return string
     */
    public string function getDataDir(string path = '')
    {
        var dataDir = application.mvc.dataDirectory;

        if (arrayContains(['/', '\'], right(dataDir, 1))) {
            dataDir = left(dataDir, len(dataDir) - 1);
        }

        return '#dataDir#\#path#';
    }

    /**
     * Gets the current timestamp.
     *
     * @return string
     */
    public string function getTimestamp()
    {
        return "#dateFormat(now(), 'yyyymmdd')##timeFormat(now(), 'HHmmss')#";
    }

    /**
     * Writes the given data to file dump.
     *
     * @return void
     */
    public void function writeDumpToFile(required any data, string file = "")
    {
        file = (len(file)) ? file : "#getDataDir()#logs\log-#getTimestamp()#.html";
        writeDump(var = data, output = file, format = "html");
    }

    /**
     * Writes the given data to file dump and also dumps it on screen.
     *
     * @return void
     */
    public void function writeDumpToBoth(required any data, string file = "")
    {
        writeDumpToFile(data, file);
        writeDump(data);
    }

    /**
     * Shorthand function for cfcookie.
     *
     * @return void
     */
    public void function cookie(required string name, required string value, required string expires)
    {
        new App.Framework.Legacy().cookie(name, value, expires);
    }

    /**
     * Find key in struct and return value, if not found, return given default.
     *
     * @return any
     */
    public any function structFindDefault(required struct object, required string key, required any defaultValue)
    {
        if (structKeyExists(object, key)) {
            return structFind(object, key);
        } else {
            return defaultValue;
        }
    }
}
