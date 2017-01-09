<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset parm.form = form>

<cfoutput>
	<cfif val(parm.form.step) is 1>
		<cfset lookup = epos.SendBarcode(parm)>
		<cfif NOT Len(lookup.error)>#val(lookup.data.id)#<cfelse>0</cfif>
	<cfelseif parm.form.step is 2>
		<cfset lookup = epos.CheckProductOnOrder(parm)>
		<cfif NOT Len(lookup.error)>
			<h2>#lookup.title# #lookup.unitsize#</h2>
			<h1>&pound;#DecimalFormat(lookup.RRP)# <cfif lookup.pm>PM</cfif></h1>
			<cfif lookup.received is lookup.boxes>TICK<cfelse>CROSS</cfif>
			<p>Booked In</p>
			<cfif lookup.received lt lookup.boxes>
				<h3>Number of Packs Remaining: #lookup.boxes-lookup.received#</h3>
			<cfelse>
				<h3>Number of Packs: #lookup.received#/#lookup.boxes#</h3>
			</cfif>
			<h3>Total Products: #lookup.qtytotal#</h3>
		<cfelse>
			<h2>#lookup.error#</h2>
			<h1>&pound;#DecimalFormat(lookup.RRP)#</h1>
			<div>#lookup.img#</div>
			#lookup.msg#
			<cfif lookup.sub>
				<cfset openitems = epos.LoadOrderProductList(parm)>
				
				<script>
					$(document).ready(function(e) { 
						$('##yes').click(function(event) {
							$('##subSelect').show();
							$('##img').hide();
							event.preventDefault();
						});
						
						$('##no').click(function(event) {
							$('##result').html("<h1>Scan product barcode</h1>");
							event.preventDefault();
						});
						
						$('##btnSetSub').click(function(event) {
							var siID = $('.subProd').val();
							var prodID = $('.subProdID').val();
							SetSubstitute(siID, prodID);
							event.preventDefault();
						});
						
						$('.subProd').chosen({ width: "300px" });
					});
				</script>
				
				<a href="javascript:void(0)" class="button sc_yes">Yes, it's a substitute</a>
				<a href="javascript:void(0)" class="button sc_no">No, cancel scan</a>
				
				<!---
				<div id="subSelect" style="display:none;">
					<div style="display:inline-block;padding:20px 0;text-align:left;">
						<p>Please select the product that '#lookup.error#' is replacing.</p>
						<input type="hidden" class="subProdID" value="#lookup.prodID#" />
						<select name="ProdonOrder" class="subProd">
							<cfset ref=0>
							<cfloop array="#openitems.list#" index="i">
								<cfif ref neq i.orderref>
									<cfset ref=i.orderref>
									</optgroup>
									<optgroup label="#i.orderref#">
								</cfif>
								<option value="#i.ID#">#i.title# #i.UnitSize# - &pound;#DecimalFormat(i.RRP)#</option>
							</cfloop>
							</optgroup>
						</select>
						<a href="##" id="btnSetSub" class="button green" style="float:none;display:inline-block;">Assign</a>
					</div>
				</div>
				--->
			</cfif>
		</cfif>
	</cfif>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>