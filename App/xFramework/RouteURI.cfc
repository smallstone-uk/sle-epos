component
{
    variables.instance.type = "";
    variables.instance.uri = "";
    variables.instance.action = "";
    variables.instance.middleware = "";
    variables.instance.args = {};

    /**
     * Constructor function for the component.
     *
     * @return any
     */
    public any function init(required string type, required string uri, required string action, string middleware = '', struct args = {})
    {
        variables.instance.type = type;
        variables.instance.uri = uri;
        variables.instance.action = action;
        variables.instance.middleware = middleware;
        variables.instance.args = args;
        return this;
    }

    /**
     * Gets the page from the URI.
     *
     * @return string
     */
    public string function getPage()
    {
        return listFirst(stripSlashes(variables.instance.uri), '/');
    }

    /**
     * Gets the raw URI.
     *
     * @return string
     */
    public string function getURI()
    {
        return variables.instance.uri;
    }

    /**
     * Gets the type.
     *
     * @return string
     */
    public string function getType()
    {
        return variables.instance.type;
    }

    /**
     * Gets the raw action.
     *
     * @return string
     */
    public string function getAction()
    {
        return variables.instance.action;
    }

    /**
     * Checks whether the URI contains variable indicators.
     *
     * @return boolean
     */
    public boolean function containsVariables()
    {
        return find('{', this.getURI()) == 0 || find('}', this.getURI()) == 0;
    }

    /**
     * Checks whether the given middleware group passes.
     *
     * @return any
     */
    public any function checkMiddleware()
    {
        if (variables.instance.middleware == '') {
            return this;
        }

        var path = getBaseDir('/App/Middleware/#variables.instance.middleware#.cfc');

        if (fileExists(path)) {
            var passes = createObject('component', 'App.Middleware.#variables.instance.middleware#').init();

            if (!isValid('boolean', passes)) {
                throw("Middleware '#variables.instance.middleware#' does not return a boolean value");
            }

            if (passes) {
                return this;
            } else {
                view('layouts.index|errors.401', {
                    'title' = 'Unauthenticated',
                    'nav' = false,
                    'heading' = 'You are not logged in',
                    'message' = 'You need to login to access that page.'
                });

                abort;
            }
        } else {
            throw("Middleware file '#path#' does not exist");
        }
    }

    /**
     * Performs the route action.
     *
     * @return any
     */
    public any function perform(struct params = {}, array orders = [])
    {
        var action = this.getAction();

        if (!structIsEmpty(variables.instance.args)) {
            params = {
                'args' = variables.instance.args
            };

            orders = ['args'];
        }

        if (endsWith(action, ['.cfm', '.cfml', 'html', 'htm', 'ico'])) {
            // Include file
            saveContent variable = "routeContent" {
                for (p in params) {
                    setVariable(p, params[p]);
                }

                include '../../#action#';
            }

            writeOutput(routeContent);
        } else {
            // Plain text
            var controller = listFirst(action, '@');

            if (fileExists(getBaseDir('App/Controllers/#controller#.cfc'))) {
                new App.Framework.Legacy().invokeMethod(
                    "App.Controllers.#controller#",
                    listLast(action, '@'),
                    params,
                    orders
                );
            } else {
                var viewFile = view().getFile(action);

                if (fileExists(viewFile)) {
                    view(action, params);
                } else {
                    writeOutput(action);
                }
            }
        }

        return this;
    }
}
