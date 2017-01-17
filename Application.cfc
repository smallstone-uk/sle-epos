component
{
    this.name = "EPOS_Production";
    this.clientStorage = "kcc_cf_sle";
    this.clientManagement = true;
    this.sessionManagement = true;
    this.applicationTimeout = createTimeSpan(2,0,0,0);
    this.sessionTimeout = createTimeSpan(0,0,60,0);
    this.setClientCookies = true;
    this.jarPaths = ["file://#getDirectoryFromPath(getCurrentTemplatePath())#"];

    // Boot Framework
    new App.Framework.Boot();

    public boolean function onApplicationStart()
    {
        application.mvc = {
            'datasource' = 'kcc_sle',
            'migrationDatasource' = 'mvc_sle',
            'dataDirectory' = (getDirectoryFromPath(getCurrentTemplatePath()) & "..\data\"),
            'baseDirectory' = getDirectoryFromPath(getCurrentTemplatePath()),
            'migrationTableName' = 'migrations'
        };

        // Load the config into application
        var config = (fileExists(getBaseDir('app.json'))) ? deserializeJSON(fileRead(getBaseDir('app.json'))) : {};
        for (key in config) { application[key] = config[key]; }

        application.site.start = now();
        application.site.basedir = getBaseDir('/');
        application.site.fileDir = getBaseDir('source/');
        application.site.normal = getUrl();
        application.site.secure = getUrl();
        application.site.dir_data = getDataDir('/');
        application.site.dir_logs = getDataDir('logs/');
        application.site.dir_invoices = getDataDir('invoices/');
        application.site.url_data = getUrl('data/');
        application.site.url_invoices = getUrl('data/invoices/');

        application.site.debug = false;
        application.site.showdumps = false;
        application.site.codePath = "code/epos15";

        return true;
    }

    public void function onRequestStart()
    {
        for (dir in ['logs/epos', 'epos', 'epos/misc', 'epos/receipts']) {
            if (!directoryExists(getDataDir(dir))) {
                directoryCreate(getDataDir(dir));
            }
        }
        
        if (structKeyExists(url, 'restart')) {
            onApplicationStart();
            onSessionStart();
            writeDumpToFile(application);
        }

        if (structKeyExists(form, 'options')) {
            application.site.debug = structKeyExists(form, 'debug');
            application.site.showdumps = structKeyExists(form, 'showdumps');
        }

        request.building = {};
        request.building.start = now();
        request.oldLocale = setLocale("English (UK)");
    }

    public any function onSessionStart()
    {
        var loc = {};

        session.started = now();
        session.currDate = "";
        session.user = {};
        session.user.id = 0;
        session.user.loggedIn = false;
        session.user.firstname = "";
        session.user.lastname = "";
        session.user.eposLevel = 6;
        session.user.prefs.empautologout = 0;

        loc.epos = createObject("component", application.site.codePath);
        loc.parm = {};
        loc.parm.form.reportDate = lsDateFormat(now(), "yyyy-mm-dd");
        loc.epos.loadTillTotals(loc.parm);
        loc.epos.loadDeals(loc.parm);
        loc.epos.loadVAT();
        loc.epos.loadCatKeys();
    }

    public any function onRequest(required string thePage)
    {
        include thePage;
        include "settings.cfm";
    }
}
