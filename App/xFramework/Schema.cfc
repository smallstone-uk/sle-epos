component
{
    this.datasource = getDatasource(true);
    this.table = "";
    this.columns = [];
    this.commands = [];
    this.relationships = [];
    this.engine = "InnoDB";
    this.charset = "utf8";
    this.collation = "utf8_bin";

    /**
     * Constructor method for schema.
     *
     * @return any
     */
    public any function init(required string table, string datasource = '')
    {
        this.table = table;

        if (len(datasource)) {
            this.datasource = datasource;
        }

        return this;
    }

    /**
     * String column.
     *
     * @return any
     */
    public any function string(required string name, numeric length = 255)
    {
        return this.addColumn('varchar(#length#)', name, ["COLLATE #this.collation#"]);
    }

    /**
     * Long text column.
     *
     * @return any
     */
    public any function longText(required string name)
    {
        return this.addColumn('longtext', name, ["COLLATE #this.collation#"]);
    }

    /**
     * Decimal column.
     *
     * @return any
     */
    public any function decimal(required string name, required numeric precision, required numeric scale)
    {
        if (precision < 1)
            precision = 1;
        if (precision > 65)
            precision = 65;
        if (scale < 0)
            scale = 0;
        if (scale > 30)
            scale = 30;
        if (scale > precision)
            scale = precision;

        return this.addColumn('decimal(#precision#,#scale#)', name);
    }

    /**
     * Integer column.
     *
     * @return any
     */
    public any function integer(required string name)
    {
        return this.addColumn('int(11)', name);
    }

    /**
     * Primary key integer ID column.
     *
     * @return any
     */
    public any function increments(required string name)
    {
        return this.integer(name).autoIncrement().primary();
    }

    /**
     * Timestamp column.
     *
     * @return any
     */
    public any function timestamp(required string name)
    {
        return this.addColumn('timestamp', name);
    }

    /**
     * Date column.
     *
     * @return any
     */
    public any function date(required string name)
    {
        return this.addColumn('date', name);
    }

    /**
     * Time column.
     *
     * @return any
     */
    public any function time(required string name)
    {
        return this.addColumn('time', name);
    }

    /**
     * Datetime column.
     *
     * @return any
     */
    public any function datetime(required string name)
    {
        return this.addColumn('datetime', name);
    }

    /**
     * Timestamp columns (created_at, updated_at).
     *
     * @return any
     */
    public any function timestamps()
    {
        this.timestamp('created_at').default('CURRENT_TIMESTAMP').nullable();
        // Not working due to MySQL version - Update to 5.6.5
        // this.datetime('updated_at').default('CURRENT_TIMESTAMP').addParam('ON UPDATE CURRENT_TIMESTAMP').nullable();
    }

    /**
     * Enum column.
     *
     * @return any
     */
    public any function enum(required string name, required array values)
    {
        return this.addColumn('enum(#listQualify(arrayToList(values, ","), "'")#)', name);
    }

    /**
     * Tiny integer column.
     *
     * @return any
     */
    public any function tinyInt(required string name)
    {
        return this.addColumn('tinyint(4)', name);
    }

    /**
     * Boolean column (tiny int).
     *
     * @return any
     */
    public any function boolean(required string name)
    {
        return this.addColumn('tinyint(1)', name).unsigned();
    }

    /**
     * Encrypted column (varbinary).
     *
     * @return any
     */
    public any function encrypted(required string name)
    {
        return this.addColumn('varbinary(255)', name);
    }

    /**
     * Add a foreign key constraint to a column.
     *
     * @return any
     */
    public any function foreign(required string name)
    {
        return this.addRelationship('FOREIGN KEY', '(#name#)');
    }

    /**
     * Drop table if it exists.
     *
     * @return any
     */
    public void function drop()
    {
        try {
            query().execute(sql = 'DROP TABLE IF EXISTS `#this.table#`;');
        } catch (any error) {
            writeDumpToFile(error, '#getBaseDir()#Database\Logs\log-#getTimestamp()#.html');
        }
    }

    /**
     * Drops the given column.
     *
     * @return any
     */
    public any function dropColumn(required string name)
    {
        try {
            query().execute(sql = "SET SESSION sql_mode = '';");
            query().execute(sql = 'ALTER TABLE `#this.table#` DROP COLUMN `#name#`;');
        } catch (any error) {
            writeDumpToFile(error, '#getBaseDir()#Database\Logs\log-#getTimestamp()#.html');
        }
    }

    /**
     * Drops the foreign key for the given column.
     *
     * @return any
     */
    public any function dropForeign(required string name)
    {
        try {
            query().execute(sql = "SET SESSION sql_mode = '';");
            query().execute(sql = 'ALTER TABLE `#this.table#` DROP FOREIGN KEY `#this.table#_#name#_ibfk`;');
        } catch (any error) {
            writeDumpToFile(error, '#getBaseDir()#Database\Logs\log-#getTimestamp()#.html');
        }
    }

    /**
     * Compile and run the create schema.
     *
     * @return any
     */
    public any function create()
    {
        try {
            query().execute(sql = "SET SESSION sql_mode = '';");
            query().execute(sql = this.compile());
            return this;
        } catch (any error) {
            writeDumpToFile(error, '#getBaseDir()#Database\Logs\log-#getTimestamp()#.html');
        }
    }

    /**
     * Compile and run the update schema.
     *
     * @return any
     */
    public any function update()
    {
        try {
            query().execute(sql = "SET SESSION sql_mode = '';");
            query().execute(sql = this.compile(false, true));
            return this;
        } catch (any error) {
            writeDumpToFile(error, '#getBaseDir()#Database\Logs\log-#getTimestamp()#.html');
        }
    }

    /**
     * Add column to schema.
     *
     * @return any
     */
    public any function addColumn(required string type, required string name, array parameters = [])
    {
        var blueprint = new App.Framework.Blueprint(type, name, parameters);
        arrayAppend(this.columns, blueprint);
        return blueprint;
    }

    /**
     * Adds a foreign key relationship to schema.
     *
     * @return any
     */
    public any function addRelationship(required string type, required string name, array parameters = [])
    {
        var blueprint = new App.Framework.Blueprint(type, name, parameters);
        arrayAppend(this.relationships, blueprint);
        return blueprint;
    }

    /**
     * Compile schema into SQL.
     *
     * @return any
     */
    public any function compile(boolean format = false, boolean update = false)
    {
        try {
            var index = 1;
            var nl = (format) ? '<br />' : '';
            var tab = (format) ? '&nbsp;&nbsp;&nbsp;&nbsp;' : '';
            var statement = (update) ? "ALTER TABLE `#this.table#`#nl#" : "#nl#CREATE TABLE IF NOT EXISTS `#this.table#` (#nl#";
            var addCol = (update) ? "ADD COLUMN " : "";
            var addForeign = (update) ? "ADD " : "";

            for (col in this.columns) {
                statement &= "#tab##addCol#`#col.name#` #col.type#";

                if (!col.canBeNull) {
                    arrayPrepend(col.parameters, "NOT NULL");
                }

                if (!arrayIsEmpty(col.parameters)) {
                    var unsignedIndex = arrayFindNoCase(col.parameters, "unsigned");
                    if (unsignedIndex != 0) {
                        var unsignedParam = col.parameters[unsignedIndex];
                        arrayDeleteAt(col.parameters, unsignedIndex);
                        arrayPrepend(col.parameters, unsignedParam);
                    }

                    statement &= " ";
                    statement &= arrayToList(col.parameters, " ");
                }

                if (index < arrayLen(this.columns)) {
                    statement &= ", #nl#";
                }

                if (!arrayIsEmpty(col.keys)) {
                    if (index == arrayLen(this.columns)) {
                        statement &= ", #nl#";
                    }

                    statement &= "#tab#";
                    statement &= arrayToList(col.keys, ", ");

                    if (index < arrayLen(this.columns)) {
                        statement &= ", #nl#";
                    }
                }

                index++;
            }

            if (!arrayIsEmpty(this.relationships)) {
                if (!arrayIsEmpty(this.columns)) {
                    statement &= ", #nl#";
                }

                index = 1;

                for (rel in this.relationships) {
                    var relColName = mid(rel.name, 2, len(rel.name) - 2);
                    statement &= "#tab##addForeign#FOREIGN KEY #this.table#_#relColName#_ibfk(#relColName#)";

                    if (!arrayIsEmpty(rel.parameters)) {
                        statement &= " ";
                        statement &= arrayToList(rel.parameters, " ");

                        if (index < arrayLen(this.relationships)) {
                            statement &= ", #nl#";
                        }
                    } else {
                        statement &= ", #nl#";
                    }

                    index++;
                }
            }

            if (!update) {
                statement &= "#nl#) ENGINE=#this.engine# DEFAULT CHARSET=#this.charset# COLLATE=#this.collation#;";
            }

            return preserveSingleQuotes(statement);
        } catch (any error) {
            writeDumpToFile(error, '#getBaseDir()#Database\Logs\log-#getTimestamp()#.html');
        }
    }

    /**
     * Gets a query object setup with defaults.
     *
     * @return query
     */
    private any function query()
    {
        var q = new Query();
        q.setDatasource(this.datasource);
        return q;
    }
}
