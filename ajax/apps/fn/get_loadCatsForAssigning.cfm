<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.employee = empID>
<cfset cats = epos.LoadAllCategories()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var tick = "icon-checkmark", cross = "icon-cross", items = [];
			
			$('.epf_cat_assignitem').click(function(event) {
				items = [];
				if ( $(this).find('span').hasClass(tick) )
					$(this).find('span')
						.removeClass(tick)
						.removeClass("green")
						.addClass(cross)
						.addClass("red");
				else
					$(this).find('span')
						.removeClass(cross)
						.removeClass("red")
						.addClass(tick)
						.addClass("green");
				$('.epf_cat_assignitem').each(function(i, e) { if ( $(e).find('span').hasClass(tick) ) items.push( $(e).attr("data-id") ); });
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/post_assignCatsToEmp.cfm",
					data: {
						"empID": "#parm.employee#",
						"items": JSON.stringify(items)
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<cfloop array="#cats#" index="item">
		<cfset isAssigned = epos.IsCatAssigned(item.epcID, parm.employee)>
		<li class="applistitem epf_cat_assignitem" data-id="#item.epcID#">
			<cfif isAssigned>
				<span class="epf_cat_itemicon green icon-checkmark"></span>
			<cfelse>
				<span class="epf_cat_itemicon red icon-cross"></span>
			</cfif>
			#item.epcTitle#
		</li>
	</cfloop>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>