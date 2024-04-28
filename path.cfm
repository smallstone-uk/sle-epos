<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Path</title>
</head>

<body>
	<cfoutput>
		#getCurrentTemplatePath()#
		<cfset thisPath = ExpandPath("*.*")> 
		<cfset currentDirectory = getDirectoryFromPath(thisPath)>
		currentDirectory = #currentDirectory#<br />
		<cfset nestdepth = ListLen(currentDirectory,"\")>
		<cfif nestdepth gt 0>
			<cfset parentDirectory = ListDeleteAt(currentDirectory,nestdepth,"\")>
		<cfelse>
			<cfset parentDirectory = currentDirectory>
		</cfif>	
		parentDirectory = #parentDirectory#<br />
		<cfset data_dir = parentDirectory & "\data\">
		<cfdirectory action="list" directory="#data_dir#" name="QDir" type="all">
		<cfdump var="#QDir#" label="QDir" expand="false">
	</cfoutput>
</body>
</html>
