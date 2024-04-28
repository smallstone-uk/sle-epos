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
    public any function view(string name = "", struct args = {}, boolean returnEarly = false)
    {
        return new App.Framework.View(name, args, returnEarly);
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
     * Returns a new authentication object.
     *
     * @return any
     */
    public any function auth()
    {
        return new App.Framework.Auth();
    }

    /**
     * Returns a new redirect object.
     *
     * @return any
     */
    public any function redirect()
    {
        return new App.Framework.Redirect();
    }

    /**
     * Returns a new email object.
     *
     * @return any
     */
    public any function email()
    {
        return new App.Framework.Email();
    }

    /**
     * Returns a new media object.
     *
     * @return any
     */
    public any function media(string file = '')
    {
        return new App.Framework.Media(file);
    }

    /**
     * Converts an XML object to struct.
     *
     * @return any
     */
    public any function xmlToStruct(required string node)
    {
        return new App.Framework.Legacy().xmlToStruct(node, structNew());
    }

    /**
     * Gets a full URL with the given path.
     *
     * @return string
     */
    public string function getUrl(string uri = '')
    {
        var protocol = (cgi.https == 'off') ? 'http' : 'https';

        if (len(uri)) {
            return '#protocol#://#cgi.server_name#/#uri#/';
        } else {
            return '#protocol#://#cgi.server_name#/';
        }
    }

    /**
     * Gets a full data directory URL with the given path.
     *
     * @return string
     */
    public string function getDataUrl(string uri = '')
    {
        return getUrl('data/#stripSlashes(uri)#');
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
    public string function getBaseDir(string path = '', boolean create = false)
    {
        var baseDir = stripTrailingSlashes(application.mvc.baseDirectory);
        var targetDir = '#baseDir#\#stripSlashes(replace(path, '/', '\', 'all'))#';

        if (create && !directoryExists(targetDir)) {
            directoryCreate(targetDir);
        }

        return targetDir;
    }

    /**
     * Gets the data directory path.
     *
     * @return string
     */
    public string function getDataDir(string path = '', boolean create = false)
    {
        var dataDir = stripTrailingSlashes(application.mvc.dataDirectory);
        var targetDir = '#dataDir#\#stripSlashes(replace(path, '/', '\', 'all'))#';

        if (create && !directoryExists(targetDir)) {
            directoryCreate(targetDir);
        }

        return targetDir;
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
        file = (len(file)) ? file : "#getDataDir('logs\log-#getTimestamp()#.html')#";
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

    /**
     * Checks whether the given string ends with the given substring(s).
     *
     * @return boolean
     */
    public boolean function endsWith(required string str, required any substr)
    {
        if (isArray(substr)) {
            for (s in substr) {
                if (right(str, len(s)) == s) {
                    return true;
                }
            }
        } else {
            if (right(str, len(substr)) == substr) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks whether the given string starts with the given substring(s).
     *
     * @return boolean
     */
    public boolean function startsWith(required string str, required any substr)
    {
        if (isArray(substr)) {
            for (s in substr) {
                if (left(str, len(s)) == s) {
                    return true;
                }
            }
        } else {
            if (left(str, len(substr)) == substr) {
                return true;
            }
        }

        return false;
    }

    /**
     * Strips leading slashes.
     *
     * @return any
     */
    public any function stripLeadingSlashes(required string str)
    {
        if (str == '/' || str == '\') {
            return '';
        }

        if (left(str, 1) == '/' || left(str, 1) == '\') {
            str = right(str, len(str) - 1);
        }

        return str;
    }

    /**
     * Strips trailing slashes.
     *
     * @return any
     */
    public any function stripTrailingSlashes(required string str)
    {
        if (str == '/' || str == '\') {
            return '';
        }

        if (right(str, 1) == '/' || right(str, 1) == '\') {
            str = left(str, len(str) - 1);
        }

        return str;
    }

    /**
     * Strips leading and trailing slashes.
     *
     * @return any
     */
    public string function stripSlashes(required string str)
    {
        return stripTrailingSlashes(stripLeadingSlashes(str));
    }

    /**
     * Strips the given string by index of the given delimiter.
     *
     * @return string
     */
    public string function stripIndex(required string str, required numeric index, required string delimiter)
    {
        var list = listToArray(str, delimiter);
        arrayDeleteAt(list, index);
        return arrayToList(list, delimiter);
    }

    /**
     * Converts the given characters in the whole string.
     *
     * @return string
     */
    public string function convertChars(required string search, required string needle, required string replacement)
    {
        return replace(search, needle, replacement, 'all');
    }

    /**
     * Joins a time object to a date object.
     *
     * @return any
     */
    public any function joinTime(required any dateValue, required any timeValue)
    {
        if (isValid("string", dateValue) && len(dateValue) == 0) {
            dateValue = createDate(year(now()), month(now()), day(now()));
        }

        if (isValid("string", timeValue) && len(timeValue) == 0) {
            timeValue = createTime(0, 0, 0);
        }

        return createDateTime(
            year(dateValue),
            month(dateValue),
            day(dateValue),
            hour(timeValue),
            minute(timeValue),
            second(timeValue)
        );
    }

    /**
     * Makes a human readable timestamp from the given datetime object(s).
     * Eg. 12 minutes ago, 1 day ago, 4 weeks ago.
     *
     * @return string
     */
    public string function humanTimeDiff(required any from, any to = {})
    {
        if (isValid("struct", to)) {
            to = now();
        }
     
        var diff = dateDiff("s", from, to);
        var since = 'Just now';
        var sMinute = 60;
        var sHour = 60 * sMinute;
        var sDay = 24 * sHour;
        var sWeek = 7 * sDay;
        var sMonth = 4 * sWeek;
        var sYear = 12 * sMonth;
     
        if (diff < sHour) {
            mins = round(diff / sMinute);
            if (mins <= 1) mins = 1;
            since = '#mins# minute';
            if (mins > 1) since &= 's';
        } else if (diff < sDay && diff >= sHour) {
            hours = round(diff / sHour);
            if (hours <= 1) hours = 1;
            since = '#hours# hour';
            if (hours > 1) since &= 's';
        } else if (diff < sWeek && diff >= sDay) {
            days = round(diff / sDay);
            if (days <= 1) days = 1;
            since = '#days# day';
            if (days > 1) since &= 's';
        } else if (diff < sMonth && diff >= sWeek) {
            weeks = round(diff / sWeek);
            since = '#weeks# week';
            if (weeks > 1) since &= 's';
        } else if (diff < sYear && diff >= sMonth) {
            months = round(diff / sMonth);
            if (months <= 1) months = 1;
            since = '#months# month';
            if (months > 1) since &= 's';
        } else if (diff >= sYear) {
            years = round(diff / sYear);
            if (years <= 1) years = 1;
            since = '#years# year';
            if (years > 1) since &= 's';
        }

        return '#since# ago';
    }

    /**
     * Gets an array of lines in the given file.
     *
     * @return array
     */
    public array function fileToLines(required string filePath)
    {
        return new App.Framework.Legacy().fileToLines(filePath);
    }

    /**
     * Gets the request view contents.
     *
     * @return string
     */
    public string function includeViewContent()
    {
        if (!structKeyExists(request, 'viewContent')) {
            return '';
        }
        
        return request.viewContent;
    }

    /**
     * Includes the view contents.
     * Doesn't support passing of arguments.
     *
     * @return any
     */
    public any function includeView(required string viewName)
    {
        var path = view().getFileRel(viewName);
        include path;
    }

    /**
     * Gets the absolute path of where this method is called from.
     *
     * @return string
     */
    public string function getCurrentPath(string uri = '')
    {
        return getDirectoryFromPath(getCurrentTemplatePath()) & uri;
    }

    /**
     * Makes a timestamp object from a string.
     * Date separators can be one of (\ / . - _ |).
     * Time separator must be colon (:).
     *
     * @return any
     */
    public any function makeTimestamp(required string ts)
    {
        var separator = '';
        var tsTime = '';
        var tsYear = -1;
        var tsMonth = -1;
        var tsDay = -1;
        var tsHour = 0;
        var tsMinute = 0;
        var tsSecond = 0;

        // Find separator used
        for (c in ['\', '/', '.', '-', '_', '|']) {
            if (find(c, ts) != 0) {
                separator = c;
                break;
            }
        }

        // Throw exception if no valid separator used
        if (separator == '') {
            throw(message = "Invalid separator used in makeTimestamp()");
            return;
        }

        // Find hour separator
        // Move time string to tsTime
        if (find(':', ts) != 0) {
            tsTime = listLast(ts, ' ');
            ts = left(ts, len(ts) - len(tsTime));
        }

        var digits = listToArray(ts, separator);
        var index = 1;
        var reverse = 1;
        var timeIndex = 1;

        // Set time values
        for (dt in listToArray(tsTime, ':')) {
            switch (timeIndex) {
                case 1: tsHour = val(dt); break;
                case 2: tsMinute = val(dt); break;
                case 3: tsSecond = val(dt); break;
            }

            timeIndex++;
        }

        // Set date values
        for (d in digits) {
            if (len(d) == 4 && index == 1) {
                tsYear = val(d);
                reverse = 10;
            } else {
                switch (index * reverse) {
                    case 1: tsDay = val(d); break;
                    case 2: tsMonth = val(d); break;
                    case 3: tsYear = val(d); break;
                    case 10: tsYear = val(d); break;
                    case 20: tsMonth = val(d); break;
                    case 30: tsDay = val(d); break;
                }
            }

            index++;
        }

        // Return timestamp object
        return createDateTime(
            tsYear,
            tsMonth,
            tsDay,
            tsHour,
            tsMinute,
            tsSecond
        );
    }

    /**
     * Gets the given environment variable or the given default value if it doesn't exist.
     *
     * @return any
     */
    public any function env(required string key, string notFound = '')
    {
        if (find('.', key) != 0) {
            var keys = listToArray(key, '.');
            var last = keys[arrayLen(keys)];
            var parent = application;

            arrayDeleteAt(keys, arrayLen(keys));

            for (k in keys) {
                if (structKeyExists(parent, k)) {
                    if (isValid('struct', parent[k])) {
                        parent = parent[k];
                        continue;
                    } else {
                        throw("Key '#k#' is not a struct.");
                    }
                } else {
                    throw("Key '#k#' does not exist in 'application'.");
                    break;
                }
            }

            return structFindDefault(parent, last, notFound);
        }

        return structFindDefault(application, key, notFound);
    }

    /**
     * Includes the given content file.
     *
     * @return string
     */
    public string function includeContent(required string name)
    {
        var paths = [];

        if (findNoCase(".", name) > 0) {
            paths = listToArray(name, ".");
        } else if (findNoCase("/", name) > 0) {
            paths = listToArray(name, "/");
        } else if (findNoCase("\", name) > 0) {
            paths = listToArray(name, "\");
        } else {
            paths = [name];
        }

        var path = getDataDir("#stripSlashes(env('site.content.relative_path'))#/#arrayToList(paths, '/')#.html");

        if (!fileExists(path)) {
            fileWrite(path, '');
        }

        var content = fileRead(path);
        return content;
    }

    /**
     * Shorthand if-else statement.
     *
     * @return string
     */
    public string function cond(required boolean condition, required string passes, string fails = '')
    {
        return (condition) ? passes : fails;
    }

    /**
     * Checks whether the given middleware passes with the current session.
     *
     * @return boolean
     */
    public boolean function middlewarePasses(required string name)
    {
        var path = getBaseDir('/App/Middleware/#name#.cfc');

        if (fileExists(path)) {
            var passes = createObject('component', 'App.Middleware.#name#').init();

            if (!isValid('boolean', passes)) {
                throw("Middleware '#name#' does not return a boolean value");
            }

            return passes;
        } else {
            throw("Middleware file '#path#' does not exist");
        }
    }
}
