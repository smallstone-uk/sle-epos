<cftry>
	<cfif NOT StructKeyExists(session,"till")>
		Your session has timed out, please log-in again.
		<cfexit>
	</cfif>
	<cfscript>
		dayHeader = new App.DayHeader();
		zCash = dayHeader.zCash();
		lottoDraws = dayHeader.lottoDraws();
		scratchCards = dayHeader.scratchCards();
		lottoPrizes = dayHeader.lottoPrizes();
		scratchPrizes = dayHeader.scratchPrizes();
		today = dayHeader.today();
		yesterday = dayHeader.yesterday();
		scratchGameData = ScratchGames();
	</cfscript>

	<cfif StructIsEmpty(yesterday)>
			<cfquery name="loc.QYesterday" datasource="#GetDataSource()#">		<!--- load product and latest stock item --->
				SELECT	*
				FROM tblepos_dayheader
				ORDER BY dhID DESC LIMIT 1;
			</cfquery>
			<cfset yesterday = {}>
			<cfloop list="#loc.QYesterday.columnList#" index="col">
   				<cfset yesterday[col] = loc.QYesterday[col][1]>
			</cfloop>
		<cfdump var="#yesterday#" label="yesterday" expand="yes" format="html" 
			output="#application.site.dir_logs#dump-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
	<cfelse>
		<cfdump var="#yesterday#" label="yesterday" expand="yes" format="html" 
			output="#application.site.dir_logs#dump-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
	</cfif>
	
	<cffunction name="ScratchGames" access="public" returntype="struct">
		<cfset var loc = {}>
		<cfset loc.result = {}>
		<cfset loc.result.games = []>
		
		<cftry>
			<cfquery name="loc.QProducts" datasource="#GetDataSource()#">		<!--- load product and latest stock item --->
				SELECT
					prodID,prodRef,prodTitle,siPackQty,siOurPrice
					FROM tblProducts
					LEFT JOIN tblStockItem ON prodID = siProduct
					INNER JOIN tblStockOrder ON soID = siOrder
					AND tblStockItem.siID = (
						SELECT MAX( siID )
						FROM tblStockItem
						WHERE prodID = siProduct
					)
					WHERE prodEPOSCatID = 251
					ORDER BY prodRef
			</cfquery>
			<cfloop query="loc.QProducts">
				<cfset ArrayAppend(loc.result.games, {
					prodID = prodID,
					prodRef = prodRef,
					prodTitle = prodTitle,
					siPackQty = siPackQty,
					siOurPrice = siOurPrice
				})>
			</cfloop>
			
		<cfcatch type="any">
			<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
				output="#application.site.dir_logs#err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
		</cfcatch>
		</cftry>
		<cfreturn loc.result>
	</cffunction>

	<cfoutput>
		<script>
			$(document).ready(function(e) {
				var dc = {
					dhcid_subtotal: 0,
					dhcid_total: 0,
					dhcid_form: "",
					dhsc_form: "",
					dhsc_total: 0
				};

				$('.lotto-ui').virtualNumpad();

				$('.ui2').virtualNumpad(function(value, field) {
					var game = field.data("game"),
						value = nf(field.data("value"), "num"),
						pack = nf(field.data('pack'), 'num');

					/*var start = nf( $('input[name="dhsc_g' + game + '_start"]').val(), "num" );
					var end = nf( $('input[name="dhsc_g' + game + '_end"]').val(), "num" );
					var qty = nf( $('input[name="dhsc_g' + game + '_qty"]').val(), "num" );
					var total = $('.dhsc_g' + game + '_total');

					if ($('input[name="dhsc_g' + game + '_start"]').val().length > 0 && $('input[name="dhsc_g' + game + '_end"]').val().length > 0) {
					//	var diff = (end < start) ? ((pack - start) + end) : (end - start);
						var diff = start - end;
						total.val(nf(diff * value, 'str'));
						$('input[name="dhsc_g' + game + '_qty"]').val(diff);
					}
*/
					var startVal = $('input[name="dhsc_g' + game + '_start"]').val().trim();
					var endVal = $('input[name="dhsc_g' + game + '_end"]').val().trim();
					
					var total = $('.dhsc_g' + game + '_total');
					var qtyField = $('input[name="dhsc_g' + game + '_qty"]');
					
					var diff = 0;
					
					if (startVal !== "") {
					
						if (endVal === "") {
							// Blank End means pack is sold out
							diff = Number(startVal) + 1;
						} else if (Number(endVal) > Number(startVal)) {
							diff = Number(startVal) + (pack - 1 - Number(endVal));
						} else {
							diff = Number(startVal) - Number(endVal);
						}
					
						total.val(nf(diff * value, 'str'));
						qtyField.val(diff);
					
					} else {
						// No active pack
						total.val("");
						qtyField.val("");
					}
					dc.dhsc_total = 0;
					for (var i = 1; i <= 8; i++) {
						dc.dhsc_total += nf($('.dhsc_g' + i + '_total').val(), "num");
					} 
					$('##scrTotal').val(nf(dc.dhsc_total, "str"));
				}, { forceCallback: true });

				$('.ui').virtualNumpad(function(value) {
					dc.dhcid_subtotal = 0;
					$('.ui').each(function(i, e) {
						var denom = parseInt($(e).val() * 100);		// get amount in pence
						dc.dhcid_subtotal += denom;
					//	console.log(denom + " total " + dc.dhcid_subtotal);
					});
					var zcash = parseInt($('.zcash').val() * 100);	// convert zcash to pence
					var diff = dc.dhcid_subtotal - zcash;		// check difference
				//	console.log(dc.dhcid_subtotal + " zcash " + zcash);
					if (Math.abs(diff) < 0.01) diff = 0;	// ignore tiny rounding errors less than 1p

					$('.subtotal').val( nf(dc.dhcid_subtotal / 100, "str") );		// show in pounds & pence
					$('.diff').val(nf(diff / 100, "str"));

					if (diff != 0)
						$('.cidFace').attr("class", "cidFace icon-sad2 error");
					else
						$('.cidFace').attr("class", "cidFace icon-smile2");
				}, { forceCallback: true });

				$('.CashInDrawerForm').submit(function(event) {
					dc.dhcid_form = $(this).serialize();
					$(this).fadeOut(function() {
						$('.ScratchcardsForm').fadeIn();
					});
					event.preventDefault();
				});

				completedRoutine = function(data) {
					// Show shop takings
					$.sidepanel(data);
				}

				$('.ScratchcardsForm').submit(function(event) {
					dc.dhsc_form = $(this).serialize();
					$(this).fadeOut(function() {
						var lottoTotal = 0;
						for (c of ['lotto_draws','lotto_sc','lotto_prizes','lotto_sc_prizes'])
							lottoTotal += Number($('input[name="' + c + '"]').val());
					//	$('input[name="lotto_sc"]').val(nf(dc.dhsc_total, "str"));
						$('input[name="lotto_total"]').val(nf(lottoTotal, "str"));
						$('.LotteryForm').fadeIn();
					});
					event.preventDefault();
				});

				$('.LotteryForm').submit(function(event) {
					$.ajax({
						type: "POST",
						url: "ajax/apps/fn/post_endOfDay.cfm",
						data: dc.dhcid_form + "&" + dc.dhsc_form,
						success: function(data) {
							completedRoutine(data);
						}
					});
					event.preventDefault();
				});

				$('.back').click(function(event) {
					var thisForm = $(this).parents('form');
					var prevForm = thisForm.prev('form');
					thisForm.fadeOut(function() {
						prevForm.fadeIn();
					});
					event.preventDefault();
				});
			});
		</script>

		<cfset poundArray = [50,20,10,5,2,1]>

		<div id="app-endofday">
			<form method="post" enctype="multipart/form-data" class="CashInDrawerForm">
				<span class="eodTitle">Cash In Drawer</span>
				<table border="0">
					<cfset tabIndex = 0>
					<cfset subTotal = 0>
					<cfloop array="#poundArray#" index="denom">
						<cfset tabIndex++>
						<cfset dataMOD = denom * 100>
						<cfset poundFld = "dhcid_#NumberFormat(dataMOD,'0000')#">
						<cfset penceFld = "dhcid_#NumberFormat(denom,'0000')#">
						<cfif StructIsEmpty(today)>
							<cfset poundValue = 0>
							<cfset penceValue = 0>
						<cfelse>
							<cfset poundValue = StructFind(today,poundFld)>
							<cfset penceValue = StructFind(today,penceFld)>
						</cfif>
						<cfset subTotal += (poundValue + penceValue)>
						<cfif poundValue eq 0><cfset poundValue = ""></cfif>
						<cfif penceValue eq 0><cfset penceValue = ""></cfif>
						<tr>
							<th>&pound;#denom#</th>
							<td><input type="text" name="#poundFld#" class="money ui" data-mod="#dataMOD#" tabindex="#tabIndex#" value="#poundValue#" /></td>
							<th>#denom#p</th>
							<td><input type="text" name="#penceFld#" class="money ui" data-mod="#denom#" tabindex="#tabIndex+6#" value="#penceValue#" /></td>
						</tr>
					</cfloop>
				</table>

				<table border="0">
					<tr>
						<th align="right">Sub Total</th>
						<td><input type="text" placeholder="GBP" class="money subtotal" value="#DecimalFormat(subTotal)#" disabled></td>
					</tr>
					<tr>
						<th align="right">Z Cash</th>
						<td><input type="text" placeholder="GBP" class="money zcash" disabled value="#DecimalFormat(session.till.total.cashINDW)#"></td>
					</tr>
					<cfset diff = subTotal - session.till.total.cashINDW>
					<cfif abs(diff) lt 0.01><cfset diff = 0></cfif>
					<tr>
						<th align="right">Difference</th>
						<td><input type="text" placeholder="GBP" class="money diff" value="#DecimalFormat(diff)#" disabled></td>
						<td align="right" colspan="2"><span class="cidFace"></span></td>
					</tr>
				</table>
				<input type="submit" class="appbtn" value="Continue">
			</form>

			<form method="post" enctype="multipart/form-data" class="ScratchcardsForm" style="display:none;">
				<span class="eodTitle">
					<span class="back icon-circle-left"></span>
					Scratchcards
				</span>
				<!---<cfdump var="#scratchGameData#" label="scratchGameData" expand="yes" format="html" 
					output="#application.site.dir_logs#dump-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">--->

				<table border="0">
					<tr>
						<th>Game</th>
						<th>Pack</th>
						<th>Value</th>
						<th>Start</th>
						<th>End</th>
						<th>Qty</th>
						<th>Total</th>
					</tr>
					<cfset game = 0>
					<cfset totalSC = 0>
					<cfloop array="#scratchGameData.games#" index="loc.item">
						<cfset game++>
						<cfset gStart = "dhsc_g#game#_start">
						<cfset gEnd = "dhsc_g#game#_end">
						<cfset sold = 0>
						<cfset value = 0>
						<cfset start = 0>
						<cfset end = 0>
						<cfif StructIsEmpty(today)>
							<cfif StructIsEmpty(yesterday)>
								<cfset start = "">
								<cfset end = "">
							<cfelse>
								<cfset start = StructFind(yesterday,gEnd)>
								<cfset end = "">
							</cfif>
						<cfelse>
							<cfset start = StructFind(today,gStart)>
							<cfset end = StructFind(today,gEnd)>
						</cfif>
						<cfset sold = val(start) - val(end)>
						<cfset value = sold * loc.item.siOurPrice>
						<cfset totalSC += value>
						<tr>
							<th>#loc.item.prodtitle#</th>
							<th>#loc.item.siPackQty#</th>
							<th>&pound;#loc.item.siOurPrice#</th>
							<td><input type="text" name="#gStart#" autocomplete="off" value="#start#" 
									data-qty="#loc.item.siPackQty#" data-value="#loc.item.siOurPrice#" data-maximum="#loc.item.siPackQty-1#"
									data-wholenumber="true" data-pack="#loc.item.siPackQty#" data-game="#game#" data-minimum="0" class="scratch ui2" 
								/>
							</td>
							<td><input type="text" name="#gEnd#" autocomplete="off" value="#end#"
									data-qty="#loc.item.siPackQty#" data-value="#loc.item.siOurPrice#" data-maximum="#loc.item.siPackQty-1#"
									data-wholenumber="true" data-pack="#loc.item.siPackQty#" data-game="#game#" data-minimum="0" class="scratch ui2" 
								/>
							</td>
							<td><input type="text" name="dhsc_g#game#_qty" value="#sold#" class="scratch ui2" disabled="disabled" /></td>
							<td><input type="text" name="dhsc_g#game#_total" value="#DecimalFormat(value)#" class="money dhsc_g#game#_total" disabled="disabled"></td>
						</tr>
					</cfloop>
<!---				<cfset totalSC = 0>
						<cfset gameValues = [5,5,3,3,2,2,1,1]>
					<cfset packQtys = [60,60,60,60,120,120,180,180]>
					<cfloop from="1" to="8" index="game">
						<cfset gStart = "dhsc_g#game#_start">
						<cfset gEnd = "dhsc_g#game#_end">
						<cfset sold = 0>
						<cfset value = 0>
						<cfif StructIsEmpty(today)>
							<cfif StructIsEmpty(yesterday)>
								<cfset start = "">
								<cfset end = "">
							<cfelse>
								<cfset start = StructFind(yesterday,gEnd)>
								<cfset end = "">
							</cfif>
						<cfelse>
							<cfset start = StructFind(today,gStart)>
							<cfset end = StructFind(today,gEnd)>
							<!---<cfif end gt 0>
								<cfset sold = val(end) - val(start)>
								<cfset value = sold * gameValues[game]>
							</cfif>--->
						</cfif>
						<cfset totalSC += value>
						<cfif end eq 0><cfset end = ""></cfif>
						<cfif sold eq 0><cfset sold = ""></cfif>
						<cfif value eq 0><cfset value = "">
							<cfelse><cfset value = DecimalFormat(value)></cfif>
						<tr>
							<th>#game# ##</th>
							<th>#packQtys[game]#</th>
							<th>&pound;#gameValues[game]#</th>
							<td><input type="text" name="#gStart#" data-qty="#packQtys[game]#" data-value="#gameValues[game]#" data-maximum="#packQtys[game]-1#"
									 data-wholenumber="true" data-pack="#packQtys[game]#" data-game="#game#" data-minimum="0" class="scratch ui2" 
									 value="#start#" /></td>
							<td><input type="text" name="#gEnd#" data-qty="#packQtys[game]#" data-value="#gameValues[game]#" data-maximum="#packQtys[game]-1#"
									 data-wholenumber="true" data-pack="#packQtys[game]#" data-game="#game#" data-minimum="0" class="scratch ui2" 
									 value="#end#" /></td>
							<td><input type="text" name="dhsc_g#game#_qty" value="#sold#" class="scratch ui2" disabled="disabled" /></td>
							<td><input type="text" name="dhsc_g#game#_total" value="#value#" class="money dhsc_g#game#_total" disabled="disabled"></td>
						</tr>
					</cfloop>
--->					<tr>
						<td colspan="6" align="right">Total</td>
						<td align="right"><input type="text" name="scrTotal" id="scrTotal" class="money" disabled="disabled" value="#DecimalFormat(totalSC)#" /></td>
					</tr>
				</table>

				<input type="submit" class="appbtn" value="Continue">
			</form>

			<form method="post" enctype="multipart/form-data" class="LotteryForm" style="display:none;">
				<span class="eodTitle">
					<span class="back icon-circle-left"></span>
					Lottery
				</span>
				<table border="0">
					<tr>
						<th align="right">Lottery Draws</th>
						<td>
							<input type="text" name="lotto_draws" class="money lotto-ui" placeholder="GBP" value="#DecimalFormat(-lottoDraws)#">
						</td>
					</tr>

					<tr>
						<th align="right">Scratchcards</th>
						<td>
							<input type="text" name="lotto_sc" class="money lotto-ui" placeholder="GBP" value="#DecimalFormat(-scratchCards)#">
						</td>
					</tr>

					<tr>
						<th align="right">Lottery Prizes</th>
						<td>
							<input type="text" name="lotto_prizes" class="money lotto-ui" placeholder="GBP" value="#DecimalFormat(-lottoPrizes)#">
						</td>
					</tr>

					<tr>
						<th align="right">Scratch Prizes</th>
						<td>
							<input type="text" name="lotto_sc_prizes" class="money lotto-ui" placeholder="GBP" value="#DecimalFormat(-scratchPrizes)#">
						</td>
					</tr>

					<tr>
						<th align="right">Lottery Total</th>
						<td>
							<input type="text" name="lotto_total" class="money lotto-ui" placeholder="GBP" value="0">
						</td>
					</tr>
				</table>

				<input type="submit" class="appbtn" value="Complete">
			</form>
		</div>
	</cfoutput>

	<cfcatch type="any">
		<cfset writeDumpToFile(cfcatch)>
	</cfcatch>
</cftry>
