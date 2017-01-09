<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset bookmarks = epos.LoadBookmarks()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.book_item_lite').click(function(event) {
				$('.book_item_lite').removeClass("alert_item_active");
				$(this).addClass("alert_item_active");
				window.pickBookmark( $(this).data("title"), $(this).data("time") );
				event.preventDefault();
			});
		});
	</script>
	<ul>
		<cfloop array="#bookmarks#" index="item">
			<li class="scalebtn book_item_lite" data-id="#item.ebID#" data-title="#item.ebTitle#" data-time="#LSTimeFormat(item.ebTime, 'HH:mm')#">
				<span class="bi_icon icon-bookmark"></span>
				<span class="bi_timestamp">#LSTimeFormat(item.ebTime, "HH:mm")#</span>
				<span class="bi_content">#item.ebTitle#</span>
			</li>
		</cfloop>
	</ul>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>