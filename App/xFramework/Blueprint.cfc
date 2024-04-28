component
{
    this.type = "";
    this.name = "";
    this.keys = [];
    this.parameters = [];
    this.canBeNull = false;

    /**
     * Constructor method for blueprint.
     *
     * @return any
     */
    public any function init(required string type, required string name, array parameters = [], array keys = [])
    {
        this.type = type;
        this.name = name;
        this.keys = keys;
        this.parameters = parameters;

        return this;
    }

    /**
     * Auto increment column.
     *
     * @return any
     */
    public any function autoIncrement()
    {
        return this.addParam('AUTO_INCREMENT');
    }

    /**
     * Mark column as primary key.
     *
     * @return any
     */
    public any function primary()
    {
        return this.addKey('PRIMARY KEY (`#this.name#`)');
    }

    /**
     * Index column.
     *
     * @return any
     */
    public any function index()
    {
        return this.addKey('KEY `#this.name#` (`#this.name#`)');
    }

    /**
     * Unique column.
     *
     * @return any
     */
    public any function unique()
    {
        return this.addKey('UNIQUE KEY `#this.name#` (`#this.name#`)');
    }

    /**
     * Set default value for column.
     *
     * @return any
     */
    public any function default(required any value)
    {
        var quotes = (isValid('string', value) && value != 'CURRENT_TIMESTAMP') ? "'" : "";

        if (listFindNoCase("true,false", value)) {
            value = (value) ? 1 : 0;
        }

        return this.addParam('DEFAULT #quotes##value##quotes#');
    }

    /**
     * Make column nullable.
     *
     * @return any
     */
    public any function nullable()
    {
        this.canBeNull = true;
        return this;
    }

    /**
     * Make column unsigned.
     *
     * @return any
     */
    public any function unsigned()
    {
        return this.addParam('UNSIGNED');
    }

    /**
     * Adds a reference to a foreign key.
     *
     * @return any
     */
    public any function references(required string table, required string column)
    {
        return this.addParam('REFERENCES #table#(#column#)');
    }

    /**
     * Adds an onDelete event to foreign key.
     *
     * @return any
     */
    public any function onDelete(required string action)
    {
        return this.addParam("ON DELETE #uCase(action)#");
    }

    /**
     * Adds an onUpdate event to foreign key.
     *
     * @return any
     */
    public any function onUpdate(required string action)
    {
        return this.addParam("ON UPDATE #uCase(action)#");
    }

    /**
     * Add parameter to column.
     *
     * @return any
     */
    public any function addParam(required string parameter)
    {
        arrayAppend(this.parameters, parameter);
        return this;
    }

    /**
     * Add key to column.
     *
     * @return any
     */
    public any function addKey(required string key)
    {
        arrayAppend(this.keys, key);
        return this;
    }
}
