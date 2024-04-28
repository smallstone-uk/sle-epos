<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var dc = {cid_subtotal: 0, cid_total: 0};
			$('.scFld').virtualNumpad();
			$('.cidSumFld').virtualNumpad(function(value) {
				/*dc.cid_subtotal = 0;
				$('.cidSumFld').each(function(i, e) {dc.cid_subtotal += nf( $(e).val(), "num" );});
				$('.cidSubTotalFld').val( nf(dc.cid_subtotal, "str") );
				$('.cidTotalFld').val( nf( ( dc.cid_subtotal - $('.cidFloatFld').val() ), "str" ) );*/
			});
			
			sections = new Sections();
			sections.complete = function() {
				$.ajax({
					type: "POST",
					url: "#parm.url#epos2/ajax/postDeclaredCash.cfm",
					data: $('##DeclareCashForm').serialize(),
					success: function(data) {
						console.log( data.toJava() );
					}
				});
			}
		});
	</script>
	<body>
		<style>
			.dcCashFld, .scFld {width:100px !important;}
		</style>
		<section>
			<form method="post" enctype="multipart/form-data" id="DeclareCashForm">
				<article data-title="Cash In Drawer">
					<div>
						<div class="col" style="width:100px;">
							<label>
								<span>&pound;50</span>
								<input type="text" name="50pound_cid" data-mod="5000" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>&pound;20</span>
								<input type="text" name="20pound_cid" data-mod="2000" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>&pound;10</span>
								<input type="text" name="10pound_cid" data-mod="1000" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>&pound;5</span>
								<input type="text" name="5pound_cid" data-mod="500" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>&pound;2</span>
								<input type="text" name="2pound_cid" data-mod="200" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>&pound;1</span>
								<input type="text" name="1pound_cid" data-mod="100" class="dcCashFld cidSumFld" />
							</label>
						</div>
						<div class="col" style="width:100px;">
							<label>
								<span>50p</span>
								<input type="text" name="50pence_cid" data-mod="50" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>20p</span>
								<input type="text" name="20pence_cid" data-mod="20" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>10p</span>
								<input type="text" name="10pence_cid" data-mod="10" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>5p</span>
								<input type="text" name="5pence_cid" data-mod="5" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>2p</span>
								<input type="text" name="2pence_cid" data-mod="2" class="dcCashFld cidSumFld" />
							</label>
							<label>
								<span>1p</span>
								<input type="text" name="1pence_cid" data-mod="1" class="dcCashFld cidSumFld" />
							</label>
						</div>
					</div>
				</article>
				<article data-title="Scratchcards">
					<div>
						<table border="1" class="sandboxTable">
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
					</div>
				</article>
			</form>
		</section>
	</body>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>