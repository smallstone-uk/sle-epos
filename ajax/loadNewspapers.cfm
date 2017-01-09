<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.form = form>
<cfset parm.daynow = LSDateFormat(Now(), "dddd")>
<cfset publications = epos.LoadNewspapers(parm)>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('.products_item').click(function(event) {
				var price = Number($(this).data("price")),
					id = $(this).data("id"),
					title = $(this).data("title"),
					cashonly = $(this).data("cashonly"),
					type = $(this).data("type");
					
				if (price > 0) {
					$.addToBasket({
						pubid: id,
						pubtitle: title,
						type: type,
						price: price,
						cash: 0,
						credit: price,
						qty: 1,
						vrate: 0.00,
						cashonly: cashonly,
						prodsign: 1,
						prodClass: "multiple",
						prodid: 0,
						account: 1,
						itemclass: "MEDIA",
					});
				} else {
					$.virtualNumpad({
						callback: function(value) {
							$.addToBasket({
								id: id,
								title: title,
								type: type,
								price: value,
								qty: 1,
								cashonly: cashonly
							});
						}
					});
				}
				
				event.preventDefault();
			});
		});
	</script>
	<div class="products">
		<ul class="products_list">
			<cfloop array="#publications#" index="item">
				<li class="products_item scalebtn" data-id="#item.id#" data-title="#item.title#" data-price="#item.price#" data-type="publication" data-cashonly="0">
					<span><strong>#item.title#</strong></span>
					<span>
						<cfif item.price gt 0>
							&pound;#DecimalFormat(item.price)#
						<cfelse>
							Manual Price
						</cfif>
					</span>
				</li>
			</cfloop>
		</ul>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>