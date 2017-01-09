<cftry>
<style>
	body {font-family:Arial, Helvetica, sans-serif;}
	table {border-spacing: 0px;border-collapse: collapse;border: 1px solid #BBB;font-size: 14px;font-weight: normal;}
	table th {padding: 4px 5px;color: inherit;font-weight: bold;background: #FFF;}
	table td {padding: 4px 5px;border-color: #BBB;color: inherit;}
	table[border="0"] {border:none;}
</style>

<cfdirectory
	directory = "#application.site.dir_logs#"
    action = "list"
    listInfo = "all"
    name = "logList"
    recurse = "yes"
    sort = "datelastmodified DESC"
    type = "all">

<cfset del = StructKeyExists(form, "delAllLogs")>
<cfif del>
	<cfloop query="logList">
		<cfif type eq "file">
			<cffile action="delete" file="#directory#\#name#">
		</cfif>
	</cfloop>
	<cflocation url="#application.site.normal#logs.cfm" addtoken="no">
</cfif>

<cfoutput>
	<form method="post" enctype="multipart/form-data">
		<input type="submit" name="delAllLogs" value="Delete All">
	</form>
	<table width="100%" border="1">
		<tr>
			<th>Date/Time</th>
			<th>Content</th>
		</tr>
		<cfloop query="logList">
			<cfif type eq "file">
				<tr>
					<td valign="top">#LSDateFormat(datelastmodified, "dd/mm/yyyy")# @ #LSTimeFormat(datelastmodified, "HH:mm")#</td>
					<td valign="top">
						<cffile action="read" file="#directory#\#name#" variable="fileContent">
						#fileContent#
					</td>
				</tr>
			</cfif>
		</cfloop>
	</table>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
</cfcatch>
</cftry>