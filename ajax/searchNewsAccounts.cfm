<cfheader
    name="Content-Type"
    value="application/json">

<cfscript>
    accounts = new code.core().searchClients(url.query);

    outputJson({ "accounts" = accounts });
</cfscript>
