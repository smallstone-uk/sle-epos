<cfscript>
    if (structKeyExists(form, 'file')) {
        m = media()
            .upload('file', '/test')
            .rename();

        writeDump(m);
    }
</cfscript>

<cfoutput>
    <form method="post" action="archiveTest.cfm" enctype="multipart/form-data">
        <input type="file" name="file">
        <input type="submit" value="Upload" name="submit">
    </form>
</cfoutput>
