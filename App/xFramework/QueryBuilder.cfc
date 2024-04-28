component
{
    this.datasource = getDatasource();
    this.queries = [];
    this.params = [];

    variables.instance.hasOrderBy = false;

    public queryBuilder function init(string datasource = "")
    {
        if (len(datasource)) {
            this.datasource = datasource;
        }
		
		variables.instance.hasOrderBy = false;

        return this;
    }

    public queryBuilder function insertInto(required string table, required any columns)
    {
        if (isValid("array", columns)) {
            columns = arrayToList(columns, ", ");
        }

        return this.add("insert").add("into", "#table# ( #columns# )");
    }

    public queryBuilder function values(required string values)
    {
        if (isValid("array", values)) {
            values = arrayToList(values, ", ");
        }

        return this.add("values", "( #values# )");
    }

    public queryBuilder function delete()
    {
        return this.add("delete");
    }

    public queryBuilder function select(required any data)
    {
        if (isValid("array", data)) {
            data = arrayToList(data, ", ");
        }

        return this.add("select", data);
    }

    public queryBuilder function update(required any data)
    {
        if (isValid("array", data)) {
            data = arrayToList(data, ", ");
        }

        return this.add("update", data);
    }

    public queryBuilder function from(required any data)
    {
        if (isValid("array", data)) {
            data = arrayToList(data, ", ");
        }

        return this.add("from", data);
    }

    public queryBuilder function set(required any data)
    {
        if (isValid("struct", data)) {
            var values = [];

            for (key in data) {
                arrayAppend(values, "#key# = #data[key]#");
            }

            data = arrayToList(values, ", ");
        }

        return this.add("set", data);
    }

    public queryBuilder function addParams(required array params)
    {
        for (param in arguments.params) {
            arrayAppend(this.params, param);
        }

        return this;
    }

    public queryBuilder function where(required string data)
    {
        return this.add("where", data);
    }

    public queryBuilder function andWhere(required string data)
    {
        return this.add("and", data);
    }

    public queryBuilder function orderBy(required string col, string dir = "asc")
    {
		var str1 = (!variables.instance.hasOrderBy) ? "order" : "";
		var str2 = (!variables.instance.hasOrderBy) ? "by" : "";
		var str3 = (variables.instance.hasOrderBy) ? "," : "";
        this.add(str1).add(str2, "#str3# #col# #dir#");
        variables.instance.hasOrderBy = true;
        return this;
    }

    public queryBuilder function limit(required string data)
    {
        return this.add("limit", data);
    }

    public queryBuilder function offset(required string data)
    {
        return this.add("offset", data);
    }

    public queryBuilder function innerJoin(required string data)
    {
        return this.add("inner").add("join", data);
    }

    public queryBuilder function leftJoin(required string data)
    {
        return this.add("left").add("join", data);
    }

    public queryBuilder function on(required struct data)
    {
        var assignments = [];

        for (key in data) {
            arrayAppend(assignments, "#key# = #data[key]#");
        }

        return this.add("on", arrayToList(assignments, ", "));
    }

    public any function run(boolean getResult = true)
    {
        try {
            var statement = this.compile();
            var schema = new Query();

            // Clear queries ready for next
            this.queries = [];
			variables.instance.hasOrderBy = false;

            schema.setDatasource(this.datasource);
            schema.setSQL(statement);

            for (param in this.params) {
                if (structKeyExists(param, 'scale')) {
                    schema.addParam(name = param.name, value = param.value, cfsqltype = param.cfsqltype, scale = param.scale);
                } else {
                    schema.addParam(name = param.name, value = param.value, cfsqltype = param.cfsqltype);
                }
            }

            var result = schema.execute();

            if (getResult) {
                return result.getResult();
            } else {
                return result;
            }
        } catch (any error) {
            writeDumpToFile(error);
        }
    }

    public queryBuilder function add(required string command, string data = "")
    {
        arrayAppend(this.queries, {
            "command" = arguments.command,
            "data" = arguments.data
        });

        return this;
    }

    public string function compile()
    {
        var statement = "";

        for (query in this.queries) {
            statement &= "#uCase(query.command)# #query.data# ";
        }

        return statement;
    }
}
