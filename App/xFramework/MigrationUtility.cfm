<cfscript>
    if (!middlewarePasses('developer')) {
        abort;
    }

    if (structKeyExists(url, 'method')) {
        try {
            switch (lCase(url.method)) {
                case 'run': new MigrationEngine().run(url.name); break;
                case 'reverse': new MigrationEngine().reverse(url.name); break;
                case 'deletelog': fileDelete("#getBaseDir()#\Database\Logs\#url.name#"); break;
            }

            location(getUrl('App/Framework/MigrationUtility.cfm'), false);
        } catch (any error) {
            writeDump(error);
        }
    }

    if (structKeyExists(form, 'method')) {
        try {
            switch (lCase(form.method)) {
                case 'run': new MigrationEngine().run(); break;
                case 'reverse': new MigrationEngine().reverse(); break;
                case 'create': new MigrationEngine().createTemplate(form.fileName); break;
            }

            location(getUrl('App/Framework/MigrationUtility.cfm'), false);
        } catch (any error) {
            writeDump(error);
        }
    }
</cfscript>

<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">

<cfoutput>
    <nav class="navbar navbar-default">
        <div class="container">
            <div class="navbar-header">
                <a href="#getUrl('App/Framework/MigrationUtility.cfm')#" class="navbar-brand">Migration Utility</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <form method="post" class="pull-left" style="margin-right:2rem">
            <input type="hidden" value="run" name="method">
            <input type="submit" value="Run All" class="btn btn-primary btn-lg">
        </form>

        <form method="post" class="pull-left" style="margin-right:2rem">
            <input type="hidden" value="reverse" name="method">
            <input type="submit" value="Reverse Last" class="btn btn-danger btn-lg">
        </form>

        <form method="post" class="pull-right">
            <input type="hidden" value="create" name="method">
            <input type="submit" value="Create Template" class="btn btn-primary btn-lg pull-right" style="margin-left:2rem">
            <input type="text" name="fileName" placeholder="Leave out timestamp and extension" class="form-control input-lg pull-right" style="width:320px">
        </form>
    </div>

    <div class="container table-responsive" style="margin-top:1rem">
        <table class="table table-bordered">
            <tr class="warning">
                <th>Untracked Migrations</th>
            </tr>
            <cfloop array="#new MigrationEngine().getUntrackedMigrations()#" index="item">
                <tr>
                    <td>
                        #item#
                        <a href="#getUrl('App/Framework/MigrationUtility.cfm?method=run&name=#item#')#" class="btn btn-primary pull-right">Run</a>
                    </td>
                </tr>
            </cfloop>
        </table>
    </div>

    <div class="container table-responsive" style="margin-top:1rem">
        <table class="table table-bordered">
            <tr class="success">
                <th>Tracked Migrations</th>
            </tr>
            <cfloop array="#new Migration().orderBy('batch', 'desc').getArray()#" index="item">
                <tr>
                    <td>
                        <strong>B#item.batch#</strong> &mdash;
                        #item.migration#
                        <a href="#getUrl('App/Framework/MigrationUtility.cfm?method=reverse&name=#item.migration#')#" class="btn btn-danger pull-right">Reverse</a>
                    </td>
                </tr>
            </cfloop>
        </table>
    </div>

    <div class="container table-responsive" style="margin-top:1rem">
        <table class="table table-bordered">
            <tr class="danger">
                <th>Error Logs</th>
            </tr>
            <cfloop array="#directoryList('#getBaseDir()#\Database\Logs', false, "name", "*.html", "name desc")#" index="item">
                <tr>
                    <td>
                        <a href="#getUrl('Database/Logs/#item#')#" target="_newtab">#item#</a>
                        <a href="#getUrl('App/Framework/MigrationUtility.cfm?method=deletelog&name=#item#')#" class="btn btn-danger pull-right">Delete</a>
                    </td>
                </tr>
            </cfloop>
        </table>
    </div>
</cfoutput>
