<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var dc = {
				cid_subtotal: 0,
				cid_total: 0
			};
			
			$('.cidSumFld').virtualNumpad(function(value) {
				dc.cid_subtotal = 0;
				$('.cidSumFld').each(function(i, e) {dc.cid_subtotal += nf( $(e).val(), "num" );});
				$('.cidSubTotalFld').val( nf(dc.cid_subtotal, "str") );
				$('.cidTotalFld').val( nf( ( dc.cid_subtotal - $('.cidFloatFld').val() ), "str" ) );
			});
			
		});
	</script>
	<table width="40%" border="1">
		 <tr>
		 	<th colspan="2">Cash in Drawer</th>
		 </tr>
		 <tr><th>£50</th><td><input type="text" name="50pound_cid" data-mod="5000" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>£20</th><td><input type="text" name="20pound_cid" data-mod="2000" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>£10</th><td><input type="text" name="10pound_cid" data-mod="1000" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>£5</th><td><input type="text" name="5pound_cid" data-mod="500" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>£2</th><td><input type="text" name="2pound_cid" data-mod="200" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>£1</th><td><input type="text" name="1pound_cid" data-mod="100" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>50p</th><td><input type="text" name="50pence_cid" data-mod="50" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>20p</th><td><input type="text" name="20pence_cid" data-mod="20" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>10p</th><td><input type="text" name="10pence_cid" data-mod="10" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>5p</th><td><input type="text" name="5pence_cid" data-mod="5" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>2p</th><td><input type="text" name="2pence_cid" data-mod="2" class="dcCashFld cidSumFld" /></td></tr>
		 <tr><th>1p</th><td><input type="text" name="1pence_cid" data-mod="1" class="dcCashFld cidSumFld" /></td></tr>
		 <tr>
		 	<th>Sub Total</th>
			<td><input type="text" name="subtotal_cid" class="dcCashFld cidSubTotalFld" /></td>
		 </tr>
		 <tr>
		 	<th>Float</th>
			<td><input type="text" name="float_cid" class="dcCashFld cidFloatFld" value="200.00" disabled="disabled" /></td>
		 </tr>
		 <tr>
		 	<th>Total</th>
			<td><input type="text" name="total_cid" class="dcCashFld cidTotalFld" /></td>
		 </tr>
	</table>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>