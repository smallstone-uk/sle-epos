component
{
    variables.datasource = getDatasource();
    variables.table = "tblModel";
    variables.meta = getMetaData(this);
    variables.ignoreDefaults = ["CURRENT_TIMESTAMP"];
    variables.columns = [];
    variables.columnTypes = {};
    variables.instance.hasSelect = false;
    variables.instance.takingSingular = false;
    variables.instance.skipAuth = false;

    /**
     * Constructor function for the component.
     *
     * @return model
     */
    public any function init(any constructorData = {})
    {
        var modelData = new App.Framework.Legacy().constructModelObject(variables.table, variables.datasource);

        variables.columns = modelData.columns;
        variables.columnTypes = modelData.columnTypes;
        variables.nullColumns = modelData.nullColumns;
        variables.instance.primaryKeyField = modelData.primaryKeyField;
        variables.instance.queryBuilder = new App.Framework.QueryBuilder(variables.datasource);

        this.fill(modelData.data, false);

        if (isValid("struct", constructorData)) {
            if (!structIsEmpty(constructorData)) {
                return this.fill(constructorData);
            }
        } else if (isValid("numeric", constructorData)) {
            return this.find(constructorData);
        }

        return this;
    }

    /**
     * Refreshes the model and returns it.
     *
     * @return any
     */
    public any function refresh()
    {
        return createObject("component", "App.#this.getModelName()#").init(this[this.getPrimaryKeyField()]);
    }

    /**
     * Called when a model is updated.
     *
     * @return any
     */
    public any function onUpdated()
    {
        return this;
    }

    /**
     * Called when a model is created.
     *
     * @return any
     */
    public any function onCreated()
    {
        return this;
    }

    /**
     * Called when a model is deleted.
     *
     * @return any
     */
    public any function onDeleted()
    {
        return this;
    }

    /**
     * Checks whether the model can be updated.
     * Return true for the update to continue.
     *
     * @return boolean
     */
    public boolean function canUpdate()
    {
        return true;
    }

    /**
     * Checks whether the model can be created.
     * Return true for the creation to continue.
     *
     * @return boolean
     */
    public boolean function canCreate()
    {
        return true;
    }

    /**
     * Checks whether the model can be deleted.
     * Return true for the deletion to continue.
     *
     * @return boolean
     */
    public boolean function canDelete()
    {
        return true;
    }

    /**
     * Called when a model is about to update.
     *
     * @return any
     */
    public any function onUpdate()
    {
        return this;
    }

    /**
     * Called when a model is about to be created.
     *
     * @return any
     */
    public any function onCreate()
    {
        return this;
    }

    /**
     * Called when a model is about to be deleted.
     *
     * @return any
     */
    public any function onDelete()
    {
        return this;
    }

    /**
     * Skips the authorisation check.
     *
     * @return any
     */
    public any function skipAuth()
    {
        variables.instance.skipAuth = true;
        return this;
    }

    /**
     * Run raw SQL string and return its result.
     *
     * @return any
     */
    public any function sql(required string statement)
    {
        var schema = new Query();
        schema.setDatasource(variables.datasource);
        schema.setSQL(statement);
        return schema.execute().getResult();
	}

    /**
     * Gets the irreversible hash function (SHA-256).
     *
     * @return string
     */
    public string function hashString(required string str, string salt = env('encryption.salt'))
    {
        return toString(variables.instance.queryBuilder
            .select("(SELECT SHA1(CONCAT('#str#', '#salt#'))) AS hash")
            .run().hash);
    }

	/**
     * Verifies the given string against an encrypted column.
     * If verification is successful, returns true.
     *
     * @return boolean
     */
    public boolean function verify(required string column, required string str)
    {
        var encryptedString = this.hashString(str);
        var colToTest = structFind(this, column);
        return (toString(encryptedString) == toString(colToTest));
    }

    /**
     * Find the given record.
     *
     * @return model
     */
    public any function find(required any id, string column = "")
    {
        var loc = {};
        loc.idCol = (len(arguments.column)) ? arguments.column : variables.instance.primaryKeyField;
        loc.colType = getType(variables.columnTypes[loc.idCol]);
        loc.schema = variables.instance.queryBuilder
            .select("*")
            .from(variables.table)
            .where("#loc.idCol# = :#loc.idCol#")
            .limit(1)
            .addParams([{
                "name" = loc.idCol,
                "value" = arguments.id,
                "cfsqltype" = loc.colType
            }])
            .run();

        if (loc.schema.recordcount == 1) {
            loc.columns = loc.schema.getColumnNames();

            for (i = 1; i <= arrayLen(loc.columns); i++) {
                this[loc.columns[i]] = loc.schema[loc.columns[i]];
            }

            return this;
        } else {
            throw(message = "Record '#arguments.id#' not found in '#variables.table#' using column '#loc.idCol#'");
        }

        return this;
    }

    /**
     * Find the given record without throwing an error if not found.
     * If not found, returns an empty struct.
     *
     * @return any
     */
    public any function findSilent(required any id, string column = "")
    {
        try {
            return this.find(id, column);
        } catch (any error) {
            return {};
        }
    }

    /**
     * Saves the record.
     *
     * @return model
     */
    public any function save(struct data = {})
    {
        if (!structIsEmpty(data)) {
            for (key in data) {
                if (structKeyExists(this, key)) {
                    this[key] = data[key];
                }
            }
        }

        return this.createOrUpdate();
    }

    /**
     * Create or update a record.
     *
     * @return model
     */
    public any function createOrUpdate()
    {
        var loc = {};
        loc.columns = getColumns();
        loc.primaryID = structFind(this, variables.instance.primaryKeyField);
        loc.exists = variables.instance.queryBuilder
            .select(variables.instance.primaryKeyField)
            .from(variables.table)
            .where("#variables.instance.primaryKeyField# = #loc.primaryID#")
            .limit(1)
            .run();

        if (loc.exists.recordcount == 1) {
            // Update
            if (!this.canUpdate() && !variables.instance.skipAuth) {
                throw('Model cannot be updated without authorisation.');
                return this;
            }

            this.onUpdate();

            loc.counter = 0;
            loc.assignments = "";

            for (loc.field in loc.columns) {
                loc.counter++;

                loc.fieldValue = structFind(this, loc.field);
                loc.fieldSQLType = getType(variables.columnTypes[loc.field]);
                loc.isFreshBinary = uCase(loc.fieldSQLType) == "CF_SQL_VARBINARY" && isValid("string", loc.fieldValue);

                if (loc.isFreshBinary) {
                    loc.assignments &= "#loc.field# = SHA1(CONCAT(:#loc.field#, :#loc.field#_saltkey))";
                    variables.instance.queryBuilder.addParams([{
                        "name" = '#loc.field#_saltkey',
                        "value" = env('encryption.salt'),
                        "cfsqltype" = "CF_SQL_VARCHAR"
                    }]);
                } else {
                    loc.assignments &= "#loc.field# = :#loc.field#";
                }
                
                if (loc.counter < arrayLen(loc.columns)) {
                    loc.assignments &= ", ";
                }

                var sqlParamData = {
                    "name" = loc.field,
                    "value" = loc.fieldValue,
                    "cfsqltype" = (loc.isFreshBinary) ? "CF_SQL_VARCHAR" : loc.fieldSQLType
                };

                if (loc.fieldSQLType == 'CF_SQL_DECIMAL') {
                    structInsert(sqlParamData, 'scale', len(listLast(loc.fieldValue, '.')));
                }

                variables.instance.queryBuilder.addParams([sqlParamData]);
            }

            loc.update = variables.instance.queryBuilder
                .update(variables.table)
                .set(loc.assignments)
                .where("#variables.instance.primaryKeyField# = #loc.primaryID#")
                .run();

            this.onUpdated();
        } else {
            // Create
            if (!this.canCreate() && !variables.instance.skipAuth) {
                throw('Model cannot be created without authorisation.');
                return this;
            }

            this.onCreate();

            loc.counter = 0;
            loc.inserts = "";

            for (loc.field in loc.columns) {
                loc.counter++;
                loc.inserts &= loc.field;
                if (loc.counter < arrayLen(loc.columns)) {
                    loc.inserts &= ", ";
                }
            }

            loc.counter = 0;
            loc.values = "";
            for (loc.field in loc.columns) {
                loc.counter++;

                loc.fieldValue = this[loc.field];
                loc.fieldSQLType = getType(variables.columnTypes[loc.field]);
                loc.isFreshBinary = loc.fieldSQLType == "CF_SQL_VARBINARY" && isValid("string", loc.fieldValue);

                if (loc.isFreshBinary) {
                    loc.values &= "SHA1(CONCAT(:#lCase(loc.field)#, :#loc.field#_saltkey))";
                    variables.instance.queryBuilder.addParams([{
                        "name" = '#loc.field#_saltkey',
                        "value" = env('encryption.salt'),
                        "cfsqltype" = "CF_SQL_VARCHAR"
                    }]);
                } else {
                    loc.values &= ":#lCase(loc.field)#";
                }
                
                if (loc.counter < arrayLen(loc.columns)) {
                    loc.values &= ", ";
                }

                var sqlParamData = {
                    "name" = lCase(loc.field),
                    "value" = loc.fieldValue,
                    "cfsqltype" = (loc.isFreshBinary) ? "CF_SQL_VARCHAR" : loc.fieldSQLType
                };

                if (uCase(loc.fieldSQLType) == 'CF_SQL_DECIMAL') {
                    structInsert(sqlParamData, 'scale', len(listLast('#loc.fieldValue#', '.')));
                }

                variables.instance.queryBuilder.addParams([sqlParamData]);
            }

            loc.createResult = variables.instance.queryBuilder
                .insertInto(variables.table, loc.inserts)
                .values(loc.values)
                .run(false);
            
            this[variables.instance.primaryKeyField] = loc.createResult.getPrefix().generatedKey;
            this.onCreated();
        }

        return this;
    }

    /**
     * Deletes the record or the given records.
     *
     * @param record(s) (optional) <numeric|array>
     * @return model
     */
    public any function delete(any records)
    {
        if (!this.canDelete() && !variables.instance.skipAuth) {
            throw('Model cannot be deleted without authorisation.');
            return this;
        }

        this.onDelete();

        if (structKeyExists(arguments, 'records')) {
            if (isValid("numeric", records)) {
                variables.instance.queryBuilder
                    .delete()
                    .from(variables.table)
                    .where("#variables.instance.primaryKeyField# = #records#")
                    .limit(1)
                    .run();
                return this;
            }

            if (isValid("array", records)) {
                variables.instance.queryBuilder
                    .delete()
                    .from(variables.table)
                    .where("#variables.instance.primaryKeyField# in ( #arrayToList(records, ', ')# )")
                    .run();
                return this;
            }
        }

        var primaryID = structFind(this, variables.instance.primaryKeyField);
        variables.instance.queryBuilder
            .delete()
            .from(variables.table)
            .where("#variables.instance.primaryKeyField# = #primaryID#")
            .limit(1)
            .run();

        this.onDeleted();
        return this;
    }

    /**
     * Gets a single model relationship.
     *
     * @param model <string>
     * @param column_start <string>
     * @param column_end (optional) <string>
     * @return model
     */
    public any function hasOne(required string model, required string columnStart, string columnEnd = "")
    {
        var id = structFind(this, arguments.columnStart);
        return createObject("component", "App.#arguments.model#").init().find(id, arguments.columnEnd);
    }

    /**
     * Gets a one-to-many model relationship.
     *
     * @param model <string>
     * @param column_start <string>
     * @param column_end (optional) <string>
     * @return array
     */
    public array function hasMany(
        required string model,
        required string columnStart,
        string columnEnd = "",
        string orderByColumn = "",
        string orderByType = "asc"
    )
    {
        var tModel = createObject("component", "App.#arguments.model#").init();
        var idStart = structFind(this, arguments.columnStart);
        var idEnd = (len(arguments.columnEnd)) ? arguments.columnEnd : tModel.getPrimaryKeyField();

        variables.instance.queryBuilder
            .select("*")
            .from(tModel.getTable())
            .where("#idEnd# = #idStart#");

        if (len(orderByColumn)) {
            variables.instance.queryBuilder
                .orderBy(orderByColumn, orderByType);
        }

        return queryToModels(
            variables.instance.queryBuilder.run(),
            arguments.model
        );
    }

    /**
     * Gets a one-to-many-to-one model relationship.
     *
     * @param model <string>
     * @param column_start <string>
     * @param column_end <string>
     * @param model <string>
     * @param column_start <string>
     * @param column_end <string>
     * @return array
     */
    public array function hasManyToOne(
        required string modelFirst,
        required string columnFirstStart,
        required string columnFirstEnd,
        required string modelLast,
        required string columnLastStart,
        required string columnLastEnd,
        string orderByColumn = "",
        string orderByType = ""
    )
    {
        var firstModel = createObject("component", "App.#modelFirst#").init();
        var lastModel = createObject("component", "App.#modelLast#").init();

        variables.instance.queryBuilder
            .select('#lastModel.getTable()#.*')
            .from('#this.getTable()#, #firstModel.getTable()#, #lastModel.getTable()#')

            .where('#this.getTable()#.#columnFirstStart# = :#this.getTable()#.#columnFirstStart#')
            .andWhere('#this.getTable()#.#columnFirstStart# = #firstModel.getTable()#.#columnFirstEnd#')
            .addParams([{
                "name" = '#this.getTable()#.#columnFirstStart#',
                "value" = this[columnFirstStart],
                "cfsqltype" = getType(variables.columnTypes[columnFirstStart])
            }])

            .andWhere('#firstModel.getTable()#.#columnLastStart# = #lastModel.getTable()#.#columnLastEnd#');

        if (len(orderByColumn)) {
            variables.instance.queryBuilder
                .orderBy(orderByColumn, orderByType);
        }

        return queryToModels(
            variables.instance.queryBuilder.run(),
            modelLast
        );
    }

    /**
     * Gets a one-to-one relationship that goes through an intermediate model.
     *
     * @return any
     */
    public any function hasOneThrough(required string related, required string through, required string throughKey, required string relatedKey)
    {
        var relatedModel = createObject("component", "App.#related#").init();
        var theThrough = this.hasOne(through, this.getPrimaryKeyField(), throughKey);
        return theThrough.hasOne(related, relatedKey, relatedModel.getPrimaryKeyField());
    }

    /**
     * Gets a one-to-one relationship this model belongs to.
     *
     * @return any
     */
    public any function belongsToOne(required string related, required string relatedKey)
    {
        var relatedModel = createObject("component", "App.#related#").init();
        return this.hasOne(related, relatedKey, relatedModel.getPrimaryKeyField());
    }

    /**
     * Gets a one-to-one relationship this model belongs to through an intermediate model.
     *
     * @return any
     */
    public any function belongsToOneThrough(required string related, required string through, required string throughKey, required string relatedKey)
    {
        var relatedModel = createObject("component", "App.#related#").init();
        var throughModel = createObject("component", "App.#through#").init();
        var theThrough = this.hasOne(through, throughKey, throughModel.getPrimaryKeyField());
        return theThrough.hasOne(related, relatedKey, relatedModel.getPrimaryKeyField());
    }

    /**
     * Gets the model's name.
     *
     * @return string
     */
    public string function getModelName()
    {
        return variables.model;
    }

    /**
     * Gets the model's table.
     *
     * @return string
     */
    public string function getTable()
    {
        return variables.table;
    }

    /**
     * Gets the model's primary ID field name.
     *
     * @return string
     */
    public string function getPrimaryKeyField()
    {
        return variables.instance.primaryKeyField;
    }

    /**
     * Converts a query to the given model.
     *
     * @param query <query>
     * @param model <string>
     * @return model
     */
    public any function queryToModel(required any query, required string model)
    {
        var loc = {};
        loc.query = queryToArrayOfStructs(query);

        for (loc.item in loc.query) {
            loc.qModel = createObject("component", "App.#arguments.model#").init();

            for (loc.key in loc.item) {
                loc.qModel[loc.key] = loc.item[loc.key];
            }

            return loc.qModel;
        }
    }

    /**
     * Converts a query to an array of the given model.
     *
     * @param query <query>
     * @param model <string>
     * @return model
     */
    public array function queryToModels(required any query, required string model)
    {
        var loc = {};
        loc.result = [];
        loc.query = queryToArrayOfStructs(arguments.query);

        for (loc.item in loc.query) {
            loc.qModel = createObject("component", "App.#arguments.model#").init();

            for (loc.key in loc.item) {
                loc.qModel[loc.key] = loc.item[loc.key];
            }

            arrayAppend(loc.result, loc.qModel);
        }
        
        return loc.result;
    }

    /**
     * Clones the object and changes the primary ID to -1 for a new record.
     * Accepts new data struct as argument.
     *
     * @return model
     */
    public any function clone(struct newData = {})
    {
        var newModel = createObject("component", "App.#variables.model#").init();

        for (key in this) {
            newModel[key] = this[key];
        }

        newModel[variables.instance.primaryKeyField] = -1;

        for (newKey in newData) {
            newModel[key] = newData[newKey];
        }

        return newModel;
    }

    /**
     * Get all records limited by the given count.
     *
     * @param limit <numeric>
     * @return array
     */
    public array function all(numeric limit = 1000)
    {
        return queryToModels(
            variables.instance.queryBuilder
                .select("*")
                .from(variables.table)
                .limit(arguments.limit)
                .run(),
            variables.model
        );
    }

    /**
     * Gets the latest record(s).
     *
     * @return any
     */
    public any function latest(numeric limit = 1, numeric skip = 0)
    {
        var records = variables.instance.queryBuilder
            .select("*")
            .from(variables.table)
            .orderBy(this.getPrimaryKeyField(), 'desc')
            .limit(arguments.limit)
            .offset(arguments.skip)
            .run();

        if (limit == 1) {
            return queryToModel(records, variables.model);
        } else {
            return queryToModels(records, variables.model);
        }
    }

    /**
     * Gets the oldest record(s).
     *
     * @return any
     */
    public any function oldest(numeric limit = 1, numeric skip = 0)
    {
        var records = variables.instance.queryBuilder
            .select("*")
            .from(variables.table)
            .orderBy(this.getPrimaryKeyField(), 'asc')
            .limit(arguments.limit)
            .offset(arguments.skip)
            .run();

        if (limit == 1) {
            return queryToModel(records, variables.model);
        } else {
            return queryToModels(records, variables.model);
        }
    }

    /**
     * Gets records that are between two timestamps using the given field.
     *
     * @return any
     */
    public any function timeframe(required string column, required any from, required any to, string order = 'asc')
    {
        return this
            .where('#column# >= #from#')
            .andWhere('#column# <= #to#')
            .orderBy(column, order)
            .getArray();
    }

    /**
     * Constructs a where clause in the query string.
     *
     * @param command <string>
     * @return model
     */
    public any function where(required string command, any value = {})
    {
        if (isValid("struct", value)) {
            if (!variables.instance.hasSelect) {
                variables.instance.hasSelect = true;
                variables.instance.queryBuilder
                    .select("*")
                    .from(variables.table)
                    .where(command);
            }
            return this;
        } else {
            var type = getType(variables.columnTypes[command]);
            variables.instance.hasSelect = true;

            if (type == "CF_SQL_VARCHAR" && isValid("boolean", value)) {
                value = (value) ? "Yes" : "No";
            } else if (type == "CF_SQL_INTEGER" && !isNumeric(value) && isValid("boolean", value)) {
                value = (value) ? 1 : 0;
            }

            variables.instance.queryBuilder
                .select("*")
                .from(variables.table)
                .where("#command# = :#command#")
                .addParams([{
                    "name" = command,
                    "value" = value,
                    "cfsqltype" = type
                }]);
            return this;
        }
    }

    /**
     * Constructs an and clause in the query string.
     *
     * @param command <string>
     * @return model
     */
    public any function andWhere(required string command, any value = {})
    {
        if (isValid("struct", value)) {
            variables.instance.queryBuilder
                .andWhere(command);
            return this;
        } else {
            var type = getType(variables.columnTypes[command]);

            if (type == "CF_SQL_VARCHAR" && isValid("boolean", value)) {
                value = (value) ? "Yes" : "No";
            } else if (type == "CF_SQL_INTEGER" && !isNumeric(value) && isValid("boolean", value)) {
                value = (value) ? 1 : 0;
            }

            variables.instance.queryBuilder
                .andWhere("#command# = :#command#")
                .addParams([{
                    "name" = command,
                    "value" = value,
                    "cfsqltype" = type
                }]);
            return this;
        }
    }

    /**
     * Constructs a left-join clause in the query string.
     *
     * @param table <string>
     * @return model
     */
    public any function leftJoin(required string data)
    {
        if (!variables.instance.hasSelect) {
            variables.instance.hasSelect = true;
            variables.instance.queryBuilder
                .select("*")
                .from(variables.table);
        }

        variables.instance.queryBuilder.leftJoin(data);
        return this;
    }

    /**
     * Constructs an inner-join clause in the query string.
     *
     * @param table <string>
     * @return model
     */
    public any function innerJoin(required string data)
    {
        if (!variables.instance.hasSelect) {
            variables.instance.hasSelect = true;
            variables.instance.queryBuilder
                .select("*")
                .from(variables.table);
        }

        variables.instance.queryBuilder.innerJoin(data);
        return this;
    }

    /**
     * Constructs an on clause in the query string.
     *
     * @param columns <struct>
     * @return model
     */
    public any function on(required struct data)
    {
        variables.instance.queryBuilder.on(data);
        return this;
    }

    /**
     * Constructs a limit clause in the query string.
     *
     * @param count <numeric>
     * @return model
     */
    public any function take(required numeric count)
    {
        variables.instance.queryBuilder.limit(arguments.count);
        variables.instance.takingSingular = arguments.count == 1;
        return this;
    }

    /**
     * Constructs an offset clause in the query string.
     *
     * @param offset <numeric>
     * @return model
     */
    public any function skip(required numeric offset)
    {
        variables.instance.queryBuilder.offset(arguments.offset);
        return this;
    }

    /**
     * Constructs a random() clause in the query string.
     *
     * @return model
     */
    public any function random()
    {
        return this.orderBy("RAND()", "");
    }

    /**
     * Constructs an order by clause in the query string.
     *
     * @param column <string>
     * @param type <string>
     * @return model
     */
    public any function orderBy(required string column, string type = "asc")
    {
        if (!variables.instance.hasSelect) {
            variables.instance.queryBuilder
                .select("*")
                .from(variables.table);
        }

        variables.instance.queryBuilder.orderBy(arguments.column, arguments.type);
        return this;
    }

    /**
     * Executes the query string and returns the model(s).
     *
     * @return model
     */
    public any function get()
    {
        var getResult = variables.instance.queryBuilder.run();
        
        variables.instance.hasSelect = false;

        if (getResult.recordcount > 1) {
            return this.queryToModels(getResult, variables.model);
        } else if (getResult.recordcount == 1) {
            return this.queryToModel(getResult, variables.model);
        } else {
            if (variables.instance.takingSingular) {
                return {};
            } else {
                return [];
            }
        }
    }

    /**
     * Executes the query string and returns the models in an array.
     *
     * @return array
     */
    public array function getArray()
    {
        var getResult = variables.instance.queryBuilder.run();
        variables.instance.hasSelect = false;
        return this.queryToModels(getResult, variables.model);
    }

    /**
     * Fills the model columns with the given data struct.
     *
     * @return model
     */
    public any function fill(required struct data, boolean explicit = true)
    {
        for (key in data) {
            if (structKeyExists(this, key) || !explicit) {
                this[key] = data[key];
            }
        }

        return this;
    }

    /**
     * Gets a query object setup with defaults.
     *
     * @return query
     */
    public any function schema()
    {
        var schema = new Query();
        schema.setDatasource(variables.datasource);
        return schema;
    }

    /**
     * Gets the query builder object.
     *
     * @return queryBuilder
     */
    public any function queryBuilder()
    {
        return variables.instance.queryBuilder;
    }

    /**
     * Gets the table columns with internal/ignored fields removed.
     *
     * @return array
     */
    private array function getColumns()
    {
        var columns = variables.columns;

        if (arrayContains(columns, variables.instance.primaryKeyField)) {
            arrayDelete(columns, variables.instance.primaryKeyField);
        }

        for (column in variables.columns) {
            var value = this[column];

            if (arrayContains(variables.ignoreDefaults, value)) {
                arrayDelete(columns, column);
            }

            if (
                arrayContains(variables.nullColumns, column) &&
                !arrayContains(['varchar', 'longtext', 'enum', 'varbinary'], variables.columnTypes[column]) &&
                !isValid('numeric', value) && isValid('string', value)
            ) {
                arrayDelete(columns, column);
            }
        }

        return columns;
    }

    /**
     * Parses the given type string to remove illegal chars.
     *
     * @param type <string>
     * @return string
     */
    private string function parseType(required string value)
    {
        return reReplace(arguments.value, "\([\d\D]*\)", "", "all");
    }

    /**
     * Gets the SQL parameter type for the given type.
     *
     * @param type <string>
     * @return string
     */
    private string function getType(required string type)
    {
        switch (lCase(arguments.type)) {
            case "int": return "CF_SQL_INTEGER"; break;
            case "bigint": return "CF_SQL_BIGINT"; break;
            case "tinyint": return "CF_SQL_TINYINT"; break;
            case "tinyint unsigned": return "CF_SQL_TINYINT"; break;
            case "int unsigned": return "CF_SQL_INTEGER"; break;
            case "timestamp": return "CF_SQL_TIMESTAMP"; break;
            case "date": return "CF_SQL_DATE"; break;
            case "datetime": return "CF_SQL_TIMESTAMP"; break;
            case "time": return "CF_SQL_TIME"; break;
            case "decimal": return "CF_SQL_DECIMAL"; break;
            case "varchar": return "CF_SQL_VARCHAR"; break;
            case "varbinary": return "CF_SQL_VARBINARY"; break;
            case "longtext": return "CF_SQL_LONGVARCHAR"; break;
            case "enum": return "CF_SQL_VARCHAR"; break;
        }

        throw(message = "[Model] Cannot find CF SQL type for '#arguments.type#'");
    }

    /**
     * Converts a query to an array of structs.
     *
     * @param query <query>
     * @return array
     */
    private array function queryToArrayOfStructs(required any query)
    {
        var loc = {};
        loc.result = [];

        for (i = 1; i <= arguments.query.recordCount; i++) {
            loc.qItem = {};
            loc.columns = arguments.query.getColumnNames();

            for (c = 1; c <= arrayLen(loc.columns); c++) {
                loc.fieldValue = arguments.query[loc.columns[c]][i];
                structInsert(loc.qItem, loc.columns[c], loc.fieldValue);
            }

            arrayAppend(loc.result, loc.qItem);
        }

        return loc.result;
    }
}
