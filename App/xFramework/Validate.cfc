component
{
    variables.instance.data = {};
    variables.instance.rules = {};

    /**
     * Constructor method for validate.
     *
     * @return any
     */
    public boolean function init(required struct data, required struct rules)
    {
        variables.instance.data = data;
        variables.instance.rules = rules;

        var result = true;

        for (key in rules) {
            var rule = structFind(rules, key);

            // Exit with false if rule is required
            // and is not present in data
            if (!structKeyExists(data, key)) {
                if (isRequired(rule)) {
                    result = false;
                    break;
                }
            } else {
                if (!parseRule(key, rule)) {
                    result = false;
                    break;
                }
            }
        }

        // Returns true if validated
        // successfully, false if not
        return result;
    }

    /**
     * Parses the rule.
     *
     * @return any
     */
    public boolean function parseRule(required string key, required string rule)
    {
        var items = listToArray(rule, '|');
        var result = true;

        for (item in items) {
            var method = listFirst(item, ':');
            var args = listLast(item, ':');
            var methodCall = getMethod(method);
            result = methodCall(key, args);
            writeDump([method, args]);
        }

        return result;
    }

    /**
     * Checks if the given rule has a required clause.
     *
     * @return boolean
     */
    public boolean function isRequired(required string rule)
    {
        return findNoCase('required', rule) != 0;
    }

    /**
     * Required clause.
     *
     * @return boolean
     */
    public boolean function required(required string key, any args = '')
    {
        return structKeyExists(variables.instance.data, key);
    }

    /**
     * Ensures the field is unique in the given model/column.
     *
     * @return boolean
     */
    public boolean function unique(required string key, any args = '')
    {
        return arrayIsEmpty(
            createObject('component', 'App.#listFirst(args, ',')#')
                .init()
                .where(listLast(args, ','), variables.instance.data[key])
                .take(1)
                .getArray()
        );
    }

    /**
     * Minimum length clause.
     *
     * @return boolean
     */
    public boolean function minLength(required string key, any args = '')
    {
        return len(variables.instance.data[key]) >= val(args);
    }

    /**
     * Maximum length clause.
     *
     * @return boolean
     */
    public boolean function maxLength(required string key, any args = '')
    {
        return len(variables.instance.data[key]) <= val(args);
    }

    /**
     * Gets a method.
     *
     * @return any
     */
    public any function getMethod(required string method)
    {
        return variables[method];
    }
}
