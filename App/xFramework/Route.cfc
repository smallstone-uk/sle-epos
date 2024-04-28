component
{
    this.ignore = [];
    this.ignoreExtensions = ['.cfm', '.cfml', 'html', 'htm', 'ico'];
    this.currentMiddleware = '';

    /**
     * Constructor function for the component.
     *
     * @return any
     */
    public any function init(string controller = "", string method = "")
    {
        if (!structKeyExists(request, 'routes')) {
            structInsert(request, 'routes', []);
        }

        if (controller == "" && method == "") {
            return this;
        }

        if (findNoCase("@", controller) > 0) {
            // Found @ - find method in controller
            var identifiers = listToArray(controller, "@");
            controller = identifiers[1];
            method = identifiers[2];
        }

        return getUrl('App/Framework/Request.cfm?controller=#controller#&method=#method#');
    }

    /**
     * Handles the request.
     *
     * @return any
     */
    public any function handle(string requestedPage = '')
    {
        if (structKeyExists(url, "controller") && structKeyExists(url, "method")) {
            var component = createObject("component", "App.Controllers.#url.controller#");
            var method = component.getMethod(url.method);
            method(form);
            return this;
        }

        if (lCase(stripSlashes(cgi.script_name)) != 'index.cfm') {
            include requestedPage;
            return this;
        }

        var payloadURI = (structKeyExists(url, 'url_payload')) ? url.url_payload : '/';
        var r = route().findURI(payloadURI);

        if (!isValid('array', r)) {
            r.checkMiddleware().perform(r.params, r.paramOrders);
        } else {
            var virtual = existsVirtually(url.url_payload);

            if (len(virtual)) {
                redirect().to(virtual);
            } else {
                view('layouts.error|errors.404', {
                    'title' = 'Page not found',
                    'message' = "Route directive for page '#url.url_payload#' using method #cgi.request_method# does not exist."
                });
            }
        }

        return this;
    }

    /**
     * Checks if the given path exists in a virtual directory.
     * Returns the full URL if found, empty string if not.
     *
     * @return string
     */
    public string function existsVirtually(required string path)
    {
        var hasExtension = listFirst(listLast(path, '/'), '.') != listLast(listLast(path, '/'), '.');
        
        for (d in env('site.virtual_paths')) {
            var p = getDataDir('/#stripSlashes(d)#/#stripSlashes(path)#');

            if (hasExtension) {
                if (fileExists(p)) {
                    return getUrl('/data/#stripSlashes(d)#/#stripSlashes(path)#');
                }
            } else {
                if (directoryExists(p)) {
                    return getUrl('/data/#stripSlashes(d)#/#stripSlashes(path)#');
                }
            }
        }

        return '';
    }

    /**
     * Adds a GET HTTP request to the pool.
     *
     * @return any
     */
    public any function get(required string uri, required string action, struct args = {})
    {
        var routeURI = new App.Framework.RouteURI('get', uri, action, this.currentMiddleware, args);
        arrayAppend(request.routes, routeURI);
        return this;
    }

    /**
     * Adds a POST HTTP request to the pool.
     *
     * @return any
     */
    public any function post(required string uri, required string action)
    {
        var routeURI = new App.Framework.RouteURI('post', uri, action, this.currentMiddleware);
        arrayAppend(request.routes, routeURI);
        return this;
    }

    /**
     * Establishes a resource route.
     * Also creates the file if it doesn't already exist.
     *
     * @return any
     */
    public any function resource(required string page, required string controller)
    {
        this.get(page, '#controller#@index');
        this.get('#page#/create', '#controller#@create');
        this.get('#page#/{id}', '#controller#@show');
        this.get('#page#/{id}/edit', '#controller#@edit');
        
        this.post(page, '#controller#@store');
        this.post('#page#/{id}', '#controller#@update');
        this.post('#page#/{id}/delete', '#controller#@delete');

        var controllerPath = getBaseDir('/App/Controllers/#controller#.cfc');

        if (!fileExists(controllerPath)) {
            saveContent variable = "templateContent" {
                include "ResourceTemplate.cfm";
            }

            fileWrite(controllerPath, templateContent);
        }
    }

    /**
     * Constructs a middleware group.
     *
     * @return any
     */
    public any function middleware(required string name)
    {
        if (len(name)) {
            this.currentMiddleware = name;
        }

        return this;
    }

    /**
     * Finds the given URI in the request routes.
     *
     * @return any
     */
    public any function findURI(required string uri)
    {
        var routeURI = [];
        var searchType = lCase(cgi.request_method);
        var searchPath = lCase(stripSlashes(uri));
        var searchPage = listFirst(searchPath, '/');
        var searchKeys = listToArray(searchPath, '/');
        var literalRoutes = [];
        var variableRoutes = [];

        for (r in request.routes) {
            if (r.containsVariables()) {
                arrayAppend(variableRoutes, r);
            } else {
                arrayAppend(literalRoutes, r);
            }
        }

        literalRoutes.addAll(variableRoutes);

        for (route in literalRoutes) {
            if (lCase(route.getType()) == searchType) {
                var routeStr = lCase(stripSlashes(route.getURI()));
                var routeKeys = listToArray(routeStr, '/');
                var keyIndex = 1;
                var ignore = false;
                var keep = false;
                var params = {};
                var paramOrders = [];

                if (arrayIsEmpty(routeKeys) && arrayIsEmpty(searchKeys)) {
                    routeURI = route;
                    routeURI.params = params;
                    routeURI.paramOrders = paramOrders;
                    break;
                }

                if (!arrayIsEmpty(searchKeys)) {
                    var hitCount = 0;

                    for (key in searchKeys) {
                        if (arrayIsDefined(routeKeys, keyIndex)) {
                            var routeSegment = routeKeys[keyIndex];

                            if (startsWith(routeSegment, '{') && endsWith(routeSegment, '}')) {
                                var rsKey = left(routeSegment, len(routeSegment) - 1);
                                rsKey = right(rsKey, len(rsKey) - 1);
                                structInsert(params, rsKey, key);
                                arrayAppend(paramOrders, rsKey);
                                routeURI = route;
                                routeURI.params = params;
                                routeURI.paramOrders = paramOrders;
                                hitCount++;
                            } else {
                                if (routeSegment == key && arrayLen(searchKeys) == arrayLen(routeKeys)) {
                                    routeURI = route;
                                    routeURI.params = params;
                                    routeURI.paramOrders = paramOrders;
                                    keyIndex++;
                                    hitCount++;
                                    continue;
                                } else {
                                    ignore = true;
                                    break;
                                }
                            }
                        } else {
                            ignore = true;
                            break;
                        }

                        keyIndex++;
                    }

                    if (hitCount == arrayLen(searchKeys)) {
                        keep = true;
                    }
                }

                if (keep) {
                    break;
                }

                if (ignore) {
                    continue;
                }
            }
        }

        if (
            isArray(routeURI) &&
            searchPath != '' &&
            !arrayContains(this.ignore, uri) &&
            !arrayContains(this.ignoreExtensions, listLast(uri, '.'))
        ) {}

        return routeURI;
    }
}
