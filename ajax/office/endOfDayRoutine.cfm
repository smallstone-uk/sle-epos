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
			
			$('.scFld').virtualNumpad();
			
			$('##DeclareCashForm').submit(function(event) {
				$.ajax({
					type: "POST",
					url: "ajax/postDeclaredCash.cfm",
					data: $('##DeclareCashForm').serialize(),
					success: function(data) {
						console.log( data.toJava() );
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<div class="close-button s-close-button">x</div>
	<div class="sandbox">
		<div class="sectionHeader">End of Day</div>
		<form method="post" enctype="multipart/form-data" id="DeclareCashForm">
			<section>
				<table width="25%" border="0" class="sandboxTable">
					<tr>
						<th colspan="4">Cash in Drawer</th>
					</tr>
					<tr>
						<th align="right">&pound;50</th>
						<td><input type="text" name="50pound_cid" data-mod="5000" class="dcCashFld cidSumFld" /></td>
						<th align="right">&pound;20</th>
						<td><input type="text" name="20pound_cid" data-mod="2000" class="dcCashFld cidSumFld" /></td>
					</tr>
					<tr>
						<th align="right">&pound;10</th>
						<td><input type="text" name="10pound_cid" data-mod="1000" class="dcCashFld cidSumFld" /></td>
						<th align="right">&pound;5</th>
						<td><input type="text" name="5pound_cid" data-mod="500" class="dcCashFld cidSumFld" /></td>
					</tr>
					<tr>
						<th align="right">&pound;2</th>
						<td><input type="text" name="2pound_cid" data-mod="200" class="dcCashFld cidSumFld" /></td>
						<th align="right">&pound;1</th>
						<td><input type="text" name="1pound_cid" data-mod="100" class="dcCashFld cidSumFld" /></td>
					</tr>
					<tr>
						<th align="right">50p</th>
						<td><input type="text" name="50pence_cid" data-mod="50" class="dcCashFld cidSumFld" /></td>
						<th align="right">20p</th>
						<td><input type="text" name="20pence_cid" data-mod="20" class="dcCashFld cidSumFld" /></td>
					</tr>
					<tr>
						<th align="right">10p</th>
						<td><input type="text" name="10pence_cid" data-mod="10" class="dcCashFld cidSumFld" /></td>
						<th align="right">5p</th>
						<td><input type="text" name="5pence_cid" data-mod="5" class="dcCashFld cidSumFld" /></td>
					</tr>
					<tr>
						<th align="right">2p</th>
						<td><input type="text" name="2pence_cid" data-mod="2" class="dcCashFld cidSumFld" /></td>
						<th align="right">1p</th>
						<td><input type="text" name="1pence_cid" data-mod="1" class="dcCashFld cidSumFld" /></td>
					</tr>
				</table>
			</section>
			<section>
				<table width="25%" border="0" class="sandboxTable">
					<tr>
						<th colspan="5">Scratchcards</th>
					</tr>
					<tr>
						<th colspan="2">Game</th>
						<th>Value</th>
						<th>Start</th>
						<th>End</th>
					</tr>
					<tr>
						<th>1</th>
						<th>20</th>
						<th>&pound;10</th>
						<td><input type="text" name="scGame_1_Start" data-wholenumber="true" class="scFld"></td>
						<td><input type="text" name="scGame_1_End" data-wholenumber="true" class="scFld"></td>
					</tr>
					<tr>
						<th>2</th>
						<th>40</th>
						<th>&pound;5</th>
						<td><input type="text" name="scGame_2_Start" data-wholenumber="true" class="scFld"></td>
						<td><input type="text" name="scGame_2_End" data-wholenumber="true" class="scFld"></td>
					</tr>
					<tr>
						<th>3</th>
						<th>40</th>
						<th>&pound;5</th>
						<td><input type="text" name="scGame_3_Start" data-wholenumber="true" class="scFld"></td>
						<td><input type="text" name="scGame_3_End" data-wholenumber="true" class="scFld"></td>
					</tr>
					<tr>
						<th>4</th>
						<th>60</th>
						<th>&pound;3</th>
						<td><input type="text" name="scGame_4_Start" data-wholenumber="true" class="scFld"></td>
						<td><input type="text" name="scGame_4_End" data-wholenumber="true" class="scFld"></td>
					</tr>
					<tr>
						<th>5</th>
						<th>80</th>
						<th>&pound;2</th>
						<td><input type="text" name="scGame_5_Start" data-wholenumber="true" class="scFld"></td>
						<td><input type="text" name="scGame_5_End" data-wholenumber="true" class="scFld"></td>
					</tr>
					<tr>
						<th>6</th>
						<th>80</th>
						<th>&pound;2</th>
						<td><input type="text" name="scGame_6_Start" data-wholenumber="true" class="scFld"></td>
						<td><input type="text" name="scGame_6_End" data-wholenumber="true" class="scFld"></td>
					</tr>
					<tr>
						<th>7</th>
						<th>160</th>
						<th>&pound;1</th>
						<td><input type="text" name="scGame_7_Start" data-wholenumber="true" class="scFld"></td>
						<td><input type="text" name="scGame_7_End" data-wholenumber="true" class="scFld"></td>
					</tr>
					<tr>
						<th>8</th>
						<th>160</th>
						<th>&pound;1</th>
						<td><input type="text" name="scGame_8_Start" data-wholenumber="true" class="scFld"></td>
						<td><input type="text" name="scGame_8_End" data-wholenumber="true" class="scFld"></td>
					</tr>
					<tr>
						<th colspan="4" align="right">Total Scratchcards Sold</th>
						<td><input type="text" name="scGame_TotalSold" class="scFld scTotalSoldFld" disabled></td>
					</tr>
				</table>
			</section>
		</form>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>