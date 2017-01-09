<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset newsArr = session.news_stories>
<cfset intIndex = RandRange(1, ArrayLen(newsArr))>
<cfset newsItem = newsArr[intIndex]>

<cfoutput>
	@title: #newsItem.title#
	@content: #newsItem.content#
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>