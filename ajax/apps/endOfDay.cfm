<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset zcash = epos.LoadZCashForToday()>
<cfset lottoDraws = epos.LoadLotteryDrawsForToday()>
<cfset lottoPrizes = epos.LoadLotteryPrizes()>
<cfset scratchPrize = epos.LoadScratchcardPrizes()>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var dc = {
				cid_subtotal: 0,
				cid_total: 0,
				cid_form: "",
				sc_form: "",
				sc_total: 0
			};
			
			$('.ui2').virtualNumpad(function(value, field) {
				var game = field.data("game"), value = nf( field.data("value"), "num" );
				var $start = nf( $('input[name="sc' + game + '_start"]').val(), "num" );
				var $end = nf( $('input[name="sc' + game + '_end"]').val(), "num" );
				var $total = $('.sc' + game + '_total');
				if ($('input[name="sc' + game + '_start"]').val().length > 0 && $('input[name="sc' + game + '_end"]').val().length > 0)
					$total.val( nf( ($end - $start) * value, "str" ) );
				dc.sc_total = 0;
				for (var i = 1; i < 8; i++) {
					dc.sc_total += nf($('.sc' + i + '_total').val(), "num");
				}
			}, { forceCallback: true });
			
			$('.ui').virtualNumpad(function(value) {
				dc.cid_subtotal = 0;
				$('.ui').each(function(i, e) {dc.cid_subtotal += nf( $(e).val(), "num" );});
				$('.subtotal').val( nf(dc.cid_subtotal, "str") );
				$('.total').val( nf( ( dc.cid_subtotal - $('.float').val() ), "str" ) );
				
				var total = nf($('.total').val(), "num");
				var zcash = nf($('.zcash').val(), "num");
				var diff = nf(total - zcash, "str");
				
				$('.diff').val(diff);
				
				if (diff > 0 || diff < 0)
					$('.cidFace').attr("class", "cidFace icon-sad2 error");
				else if (diff == 0)
					$('.cidFace').attr("class", "cidFace icon-smile2");
			}, { forceCallback: true });
			
			$('.CashInDrawerForm').submit(function(event) {
				dc.cid_form = $(this).serialize();
				$(this).fadeOut(function() {
					$('.ScratchcardsForm').fadeIn();
				});
				event.preventDefault();
			});
			
			completedRoutine = function() {
				// Show shop takings
			}
			
			$('.ScratchcardsForm').submit(function(event) {
				dc.sc_form = $(this).serialize();
				$(this).fadeOut(function() {
					$('input[name="lotto_sc"]').val(nf(dc.sc_total, "str"));
					$('.LotteryForm').fadeIn();
				});
				event.preventDefault();
			});
			
			$('.LotteryForm').submit(function(event) {
				$.ajax({
					type: "POST",
					url: "ajax/apps/fn/post_endOfDay.cfm",
					data: dc.cid_form + "&" + dc.sc_form,
					success: function(data) {
						if (data.trim() == "true") {
							completedRoutine();
						}
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
	<form method="post" enctype="multipart/form-data" class="CashInDrawerForm">
		<span class="title">Cash In Drawer</span>
		<table border="0">
			<tr>
				<th align="right">&pound;50</th><td><input type="text" name="cid5000" class="money ui" data-mod="5000" placeholder="GBP" tabindex="1"></td>
				<th align="right">50p</th><td><input type="text" name="cid50" class="money ui" data-mod="50" placeholder="GBP" tabindex="7"></td>
			</tr>
			<tr>
				<th align="right">&pound;20</th><td><input type="text" name="cid2000" class="money ui" data-mod="2000" placeholder="GBP" tabindex="2"></td>
				<th align="right">20p</th><td><input type="text" name="cid20" class="money ui" data-mod="20" placeholder="GBP" tabindex="8"></td>
			</tr>
			<tr>
				<th align="right">&pound;10</th><td><input type="text" name="cid1000" class="money ui" data-mod="1000" placeholder="GBP" tabindex="3"></td>
				<th align="right">10p</th><td><input type="text" name="cid10" class="money ui" data-mod="10" placeholder="GBP" tabindex="9"></td>
			</tr>
			<tr>
				<th align="right">&pound;5</th><td><input type="text" name="cid500" class="money ui" data-mod="500" placeholder="GBP" tabindex="4"></td>
				<th align="right">5p</th><td><input type="text" name="cid5" class="money ui" data-mod="5" placeholder="GBP" tabindex="10"></td>
			</tr>
			<tr>
				<th align="right">&pound;2</th><td><input type="text" name="cid200" class="money ui" data-mod="200" placeholder="GBP" tabindex="5"></td>
				<th align="right">2p</th><td><input type="text" name="cid2" class="money ui" data-mod="2" placeholder="GBP" tabindex="11"></td>
			</tr>
			<tr>
				<th align="right">&pound;1</th><td><input type="text" name="cid100" class="money ui" data-mod="100" placeholder="GBP" tabindex="6"></td>
				<th align="right">1p</th><td><input type="text" name="cid1" class="money ui" data-mod="1" placeholder="GBP" tabindex="12"></td>
			</tr>
		</table>
		<table border="0">
			<tr><th align="right">Sub Total</th><td><input type="text" placeholder="GBP" class="money subtotal" disabled></td></tr>
			<tr><th align="right">Float</th><td><input type="text" placeholder="GBP" class="money float" value="200.00" disabled></td></tr>
			<tr><th align="right">Total</th><td><input type="text" placeholder="GBP" class="money total" disabled></td></tr>
			<tr><th align="right">Z Cash</th><td><input type="text" placeholder="GBP" class="money zcash" disabled value="#zcash#"></td></tr>
			<tr><th align="right">Difference</th><td><input type="text" placeholder="GBP" class="money diff" disabled></td><td align="right" colspan="2"><span class="cidFace"></span></td></tr>
		</table>
		<input type="submit" class="appbtn" value="Continue">
	</form>
	<form method="post" enctype="multipart/form-data" class="ScratchcardsForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left"></span>Scratchcards</span>
		<table border="0">
			<tr><th>Game</th><th>Qty</th><th>Value</th><th>Start</th><th>End</th><th>Total</th></tr>
			<tr>
				<th>1</th><th>20</th><th>&pound;10</th>
				<td><input type="text" name="sc1_start" data-qty="20" data-value="10" data-game="1" data-maximum="19" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" name="sc1_end" data-qty="20" data-value="10" data-game="1" data-maximum="19" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" class="money sc1_total" placeholder="GBP"></td>
			</tr>
			<tr>
				<th>2</th><th>40</th><th>&pound;5</th>
				<td><input type="text" name="sc2_start" data-qty="40" data-value="5" data-game="2" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" name="sc2_end" data-qty="40" data-value="5" data-game="2" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" class="money sc2_total" placeholder="GBP"></td>
			</tr>
			<tr>
				<th>3</th><th>40</th><th>&pound;5</th>
				<td><input type="text" name="sc3_start" data-qty="40" data-value="5" data-game="3" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" name="sc3_end" data-qty="40" data-value="5" data-game="3" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" class="money sc3_total" placeholder="GBP"></td>
			</tr>
			<tr>
				<th>4</th><th>60</th><th>&pound;3</th>
				<td><input type="text" name="sc4_start" data-qty="60" data-value="3" data-game="4" data-maximum="59" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" name="sc4_end" data-qty="60" data-value="3" data-game="4" data-maximum="59" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" class="money sc4_total" placeholder="GBP"></td>
			</tr>
			<tr>
				<th>5</th><th>80</th><th>&pound;2</th>
				<td><input type="text" name="sc5_start" data-qty="80" data-value="2" data-game="5" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" name="sc5_end" data-qty="80" data-value="2" data-game="5" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" class="money sc5_total" placeholder="GBP"></td>
			</tr>
			<tr>
				<th>6</th><th>80</th><th>&pound;2</th>
				<td><input type="text" name="sc6_start" data-qty="80" data-value="2" data-game="6" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" name="sc6_end" data-qty="80" data-value="2" data-game="6" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" class="money sc6_total" placeholder="GBP"></td>
			</tr>
			<tr>
				<th>7</th><th>160</th><th>&pound;1</th>
				<td><input type="text" name="sc7_start" data-qty="160" data-value="1" data-game="7" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" name="sc7_end" data-qty="160" data-value="1" data-game="7" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" class="money sc7_total" placeholder="GBP"></td>
			</tr>
			<tr>
				<th>8</th><th>160</th><th>&pound;1</th>
				<td><input type="text" name="sc8_start" data-qty="160" data-value="1" data-game="8" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" name="sc8_end" data-qty="160" data-value="1" data-game="8" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty"></td>
				<td><input type="text" class="money sc8_total" placeholder="GBP"></td>
			</tr>
		</table>
		<input type="submit" class="appbtn" value="Continue">
	</form>
	<form method="post" enctype="multipart/form-data" class="LotteryForm" style="display:none;">
		<span class="title"><span class="back icon-circle-left"></span>Lottery</span>
		<table border="0">
			<tr><th align="right">Lottery Draws</th><td><input type="text" name="lotto_draws" class="money" placeholder="GBP" value="#DecimalFormat(-lottoDraws)#"></td></tr>
			<tr><th align="right">Scratchcards</th><td><input type="text" name="lotto_sc" class="money" placeholder="GBP"></td></tr>
			<tr><th align="right">Lottery Prizes</th><td><input type="text" name="lotto_prizes" class="money" placeholder="GBP" value="#DecimalFormat(-lottoPrizes)#"></td></tr>
			<tr><th align="right">Scratch Prizes</th><td><input type="text" name="lotto_sc_prizes" class="money" placeholder="GBP" value="#DecimalFormat(-scratchPrize)#"></td></tr>
			<tr><th align="right">Lottery Total</th><td><input type="text" name="lotto_total" class="money" placeholder="GBP"></td></tr>
		</table>
		<input type="submit" class="appbtn" value="Complete">
	</form>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>