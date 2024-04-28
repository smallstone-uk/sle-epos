component
{
    /**
     * Constructor method for migration engine.
     *
     * @return any
     */
    public any function init()
    {
        // Create migration table if it doesn't exist
        if (!this.migrationTableExists()) {
            this.createMigrationTable();
        }
    }

    /**
     * Runs any migrations unknown to the database.
     *
     * @return any
     */
    public any function run(string name = "", boolean force = false)
    {
        try {
            if (len(name)) {
                var mObject = createObject("component", "Database.Migrations.#stripSlashes(name)#");
                var mModel = new Migration().where('migration', name).take(1).getArray();

                if (!arrayIsEmpty(mModel)) {
                    mModel[1].delete();
                }

                if (force) {
                    mObject.down();
                }

                mObject.up();

                new Migration({
                    'migration' = name,
                    'batch' = this.getNewBatchNumber()
                }).save();

                return;
            }

            var batchNumber = this.getNewBatchNumber();

            for (migration in this.getUntrackedMigrations()) {
                createObject("component", "Database.Migrations.#migration#").up();
                new Migration({
                    'migration' = migration,
                    'batch' = batchNumber
                }).save();
            }
        } catch (any error) {
            writeDumpToFile(error, '#getBaseDir()#Database\Logs\log-#getTimestamp()#.html');
        }
    }

    /**
     * Reverses the latest batch of migrations.
     *
     * @return any
     */
    public any function reverse(string name = "")
    {
        if (len(name)) {
            createObject("component", "Database.Migrations.#name#").down();
            new Migration().where('migration', name).take(1).get().delete();
            return;
        }

        for (migration in this.getLatestMigrations()) {
            createObject("component", "Database.Migrations.#migration.migration#").down();
            new Migration(migration.id).delete();
        }
    }

    /**
     * Gets the latest batch number.
     * Returns 0 if no batches found.
     *
     * @return numeric
     */
    public numeric function getLatestBatchNumber()
    {
        var highest = new Migration().orderBy('batch', 'desc').getArray();

        if (arrayIsEmpty(highest)) {
            return 0;
        }

        return highest[1].batch;
    }

    /**
     * Gets a new batch number (1 more than the highest current batch number).
     *
     * @return numeric
     */
    public numeric function getNewBatchNumber()
    {
        return this.getLatestBatchNumber() + 1;
    }

    /**
     * Gets the latest tracked migrations as model objects.
     *
     * @return array
     */
    public array function getLatestMigrations()
    {
        var result = [];
        var tracked = new Migration().orderBy('batch', 'desc').getArray();

        if (arrayIsEmpty(tracked)) {
            return [];
        }

        var latestBatch = tracked[1].batch;

        for (migration in tracked) {
            if (migration.batch == latestBatch) {
                arrayAppend(result, migration);
            }
        }

        return result;
    }

    /**
     * Gets a list of untracked migration files.
     *
     * @return array
     */
    public array function getUntrackedMigrations()
    {
        var result = [];
        var tracked = new Migration().all();
        var files = directoryList('#getBaseDir()#\Database\Migrations', false, "name", "*.cfc", "name asc");

        for (fileName in files) {
            var name = listFirst(fileName, ".");
            var isTracked = false;

            for (m in tracked) {
                if (lCase(m.migration) == lCase(name)) {
                    isTracked = true;
                    break;
                }
            }

            if (!isTracked) {
                arrayAppend(result, name);
            }
        }

        return result;
    }

    /**
     * Creates a migration file template in Database\Migrations.
     *
     * @return any
     */
    public any function createTemplate(required string name)
    {
        saveContent variable = "templateContent" {
            include "MigrationTemplate.cfm";
        }

        fileWrite(
            getBaseDir('Database\Migrations\#dateFormat(now(), 'yyyy_mm_dd')#_#timeFormat(now(), 'HHmmss')#_#name#.cfc'),
            templateContent
        );
    }

    /**
     * Creates the migration table.
     *
     * @return any
     */
    public any function createMigrationTable()
    {
        var table = schema(application.mvc.migrationTableName);
        table.increments('id');
        table.timestamps();
        table.string('migration');
        table.integer('batch').unsigned().default(1);
        table.create();
    }

    /**
     * Checks whether the migration table exists.
     *
     * @return any
     */
    public any function migrationTableExists()
    {
        return new QueryBuilder(getDatasource(true))
            .add("SHOW TABLES LIKE '#application.mvc.migrationTableName#'")
            .run()
            .recordcount != 0;
    }
}
