<cfscript>
    accounts = new code.core().searchClients(jsonForm().query);

    outputJson({ "accounts" = accounts });
</cfscript>
