<cftry>
	<cfscript>
		dayHeader = new App.DayHeader();
		zCash = dayHeader.zCash();
		lottoDraws = dayHeader.lottoDraws();
		lottoPrizes = dayHeader.lottoPrizes();
		scratchPrizes = dayHeader.scratchPrizes();
	</cfscript>

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
					var game = field.data("game"), value = nf( field.data("value"), "num" );
					var $start = nf( $('input[name="dhsc_g' + game + '_start"]').val(), "num" );
					var $end = nf( $('input[name="dhsc_g' + game + '_end"]').val(), "num" );
					var $qty = nf( $('input[name="dhsc_g' + game + '_qty"]').val(), "num" );
					var $total = $('.dhsc_g' + game + '_total');
					if ($('input[name="dhsc_g' + game + '_start"]').val().length > 0 && $('input[name="dhsc_g' + game + '_end"]').val().length > 0)
						$total.val( nf( ($end - $start) * value, "str" ) );
						$('input[name="dhsc_g' + game + '_qty"]').val($end - $start);
					dc.dhsc_total = 0;
					for (var i = 1; i <= 8; i++) {
						dc.dhsc_total += nf($('.dhsc_g' + i + '_total').val(), "num");
					}
				}, { forceCallback: true });
				
				$('.ui').virtualNumpad(function(value) {
					dc.dhcid_subtotal = 0;
					$('.ui').each(function(i, e) {
						var denom = parseInt($(e).val() * 100);		// get amount in pence
						dc.dhcid_subtotal += denom;
					});
					var zcash = parseInt($('.zcash').val() * 100);	// convert zcash to pence
					var diff = dc.dhcid_subtotal - zcash;		// check difference
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
				
				completedRoutine = function() {
					// Show shop takings
				}
				
				$('.ScratchcardsForm').submit(function(event) {
					dc.dhsc_form = $(this).serialize();
					$(this).fadeOut(function() {
						var lottoTotal = 0;
						for (c of ['lotto_draws', 'lotto_sc', 'lotto_prizes', 'lotto_dhsc_prizes'])
							lottoTotal += Number($('input[name="' + c + '"]').val());
						$('input[name="lotto_sc"]').val(nf(dc.dhsc_total, "str"));
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
					<th align="right">&pound;50</th>

					<td>
						<input type="text" name="dhcid_5000" class="money ui" data-mod="5000" placeholder="GBP" tabindex="1">
					</td>

					<th align="right">50p</th>

					<td>
						<input type="text" name="dhcid_0050" class="money ui" data-mod="50" placeholder="GBP" tabindex="7">
					</td>
				</tr>

				<tr>
					<th align="right">&pound;20</th>

					<td>
						<input type="text" name="dhcid_2000" class="money ui" data-mod="2000" placeholder="GBP" tabindex="2">
					</td>

					<th align="right">20p</th>

					<td>
						<input type="text" name="dhcid_0020" class="money ui" data-mod="20" placeholder="GBP" tabindex="8">
					</td>
				</tr>

				<tr>
					<th align="right">&pound;10</th>

					<td>
						<input type="text" name="dhcid_1000" class="money ui" data-mod="1000" placeholder="GBP" tabindex="3">
					</td>

					<th align="right">10p</th>

					<td>
						<input type="text" name="dhcid_0010" class="money ui" data-mod="10" placeholder="GBP" tabindex="9">
					</td>
				</tr>

				<tr>
					<th align="right">&pound;5</th>

					<td>
						<input type="text" name="dhcid_0500" class="money ui" data-mod="500" placeholder="GBP" tabindex="4">
					</td>

					<th align="right">5p</th>

					<td>
						<input type="text" name="dhcid_0005" class="money ui" data-mod="5" placeholder="GBP" tabindex="10">
					</td>
				</tr>

				<tr>
					<th align="right">&pound;2</th>

					<td>
						<input type="text" name="dhcid_0200" class="money ui" data-mod="200" placeholder="GBP" tabindex="5">
					</td>

					<th align="right">2p</th>

					<td>
						<input type="text" name="dhcid_0002" class="money ui" data-mod="2" placeholder="GBP" tabindex="11">
					</td>
				</tr>

				<tr>
					<th align="right">&pound;1</th>

					<td>
						<input type="text" name="dhcid_0100" class="money ui" data-mod="100" placeholder="GBP" tabindex="6">
					</td>

					<th align="right">1p</th>

					<td>
						<input type="text" name="dhcid_0001" class="money ui" data-mod="1" placeholder="GBP" tabindex="12">
					</td>
				</tr>
			</table>

			<table border="0">
				<tr>
					<th align="right">Sub Total</th>

					<td>
						<input type="text" placeholder="GBP" class="money subtotal" disabled>
					</td>
				</tr>

				<tr>
					<th align="right">Z Cash</th>

					<td>
						<input type="text" placeholder="GBP" class="money zcash" disabled value="#DecimalFormat(zCash + (session.till.total.float * -1))#">
					</td>
				</tr>

				<tr>
					<th align="right">Difference</th>

					<td>
						<input type="text" placeholder="GBP" class="money diff" disabled></td><td align="right" colspan="2"><span class="cidFace"></span>
					</td>
				</tr>
			</table>

			<input type="submit" class="appbtn" value="Continue">
		</form>

		<form method="post" enctype="multipart/form-data" class="ScratchcardsForm" style="display:none;">
			<span class="title">
				<span class="back icon-circle-left"></span>
				Scratchcards
			</span>

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

				<tr>
					<th>1</th>
					<th>20</th>
					<th>&pound;10</th>

					<td>
						<input type="text" name="dhsc_g1_start" data-qty="20" data-value="10" data-game="1" data-maximum="19" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g1_end" data-qty="20" data-value="10" data-game="1" data-maximum="19" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g1_qty" data-qty="20" data-value="10" data-game="1" data-maximum="19" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty">
					</td>

					<td>
						<input type="text" name="dhsc_g1_total" class="money dhsc_g1_total" placeholder="GBP">
					</td>
				</tr>

				<tr>
					<th>2</th>
					<th>40</th>
					<th>&pound;5</th>

					<td>
						<input type="text" name="dhsc_g2_start" data-qty="40" data-value="5" data-game="2" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g2_end" data-qty="40" data-value="5" data-game="2" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g2_qty" data-qty="40" data-value="5" data-game="2" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty">
					</td>

					<td>
						<input type="text" name="dhsc_g2_total" class="money dhsc_g2_total" placeholder="GBP">
					</td>
				</tr>

				<tr>
					<th>3</th>
					<th>40</th>
					<th>&pound;5</th>

					<td>
						<input type="text" name="dhsc_g3_start" data-qty="40" data-value="5" data-game="3" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g3_end" data-qty="40" data-value="5" data-game="3" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g3_qty" data-qty="40" data-value="5" data-game="3" data-maximum="39" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty">
					</td>

					<td>
						<input type="text" name="dhsc_g3_total" class="money dhsc_g3_total" placeholder="GBP">
					</td>
				</tr>

				<tr>
					<th>4</th>
					<th>60</th>
					<th>&pound;3</th>

					<td>
						<input type="text" name="dhsc_g4_start" data-qty="60" data-value="3" data-game="4" data-maximum="59" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g4_end" data-qty="60" data-value="3" data-game="4" data-maximum="59" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g4_qty" data-qty="60" data-value="3" data-game="4" data-maximum="59" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty">
					</td>

					<td>
						<input type="text" name="dhsc_g4_total" class="money dhsc_g4_total" placeholder="GBP">
					</td>
				</tr>

				<tr>
					<th>5</th>
					<th>80</th>
					<th>&pound;2</th>

					<td>
						<input type="text" name="dhsc_g5_start" data-qty="80" data-value="2" data-game="5" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g5_end" data-qty="80" data-value="2" data-game="5" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g5_qty" data-qty="80" data-value="2" data-game="5" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty">
					</td>

					<td>
						<input type="text" name="dhsc_g5_total" class="money dhsc_g5_total" placeholder="GBP">
					</td>
				</tr>

				<tr>
					<th>6</th>
					<th>80</th>
					<th>&pound;2</th>

					<td>
						<input type="text" name="dhsc_g6_start" data-qty="80" data-value="2" data-game="6" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g6_end" data-qty="80" data-value="2" data-game="6" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g6_qty" data-qty="80" data-value="2" data-game="6" data-maximum="79" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty">
					</td>

					<td>
						<input type="text" name="dhsc_g6_total" class="money dhsc_g6_total" placeholder="GBP">
					</td>
				</tr>

				<tr>
					<th>7</th>
					<th>160</th>
					<th>&pound;1</th>

					<td>
						<input type="text" name="dhsc_g7_start" data-qty="160" data-value="1" data-game="7" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g7_end" data-qty="160" data-value="1" data-game="7" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g7_qty" data-qty="160" data-value="1" data-game="7" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty">
					</td>

					<td>
						<input type="text" name="dhsc_g7_total" class="money dhsc_g7_total" placeholder="GBP">
					</td>
				</tr>

				<tr>
					<th>8</th>
					<th>160</th>
					<th>&pound;1</th>

					<td>
						<input type="text" name="dhsc_g8_start" data-qty="160" data-value="1" data-game="8" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g8_end" data-qty="160" data-value="1" data-game="8" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="##">
					</td>

					<td>
						<input type="text" name="dhsc_g8_qty" data-qty="160" data-value="1" data-game="8" data-maximum="159" data-minimum="0" data-wholenumber="true" class="money ui2" placeholder="Qty">
					</td>

					<td>
						<input type="text" name="dhsc_g8_total" class="money dhsc_g8_total" placeholder="GBP">
					</td>
				</tr>
			</table>

			<input type="submit" class="appbtn" value="Continue">
		</form>

		<form method="post" enctype="multipart/form-data" class="LotteryForm" style="display:none;">
			<span class="title">
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
						<input type="text" name="lotto_sc" class="money lotto-ui" placeholder="GBP">
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
						<input type="text" name="lotto_total" class="money lotto-ui" placeholder="GBP">
					</td>
				</tr>
			</table>

			<input type="submit" class="appbtn" value="Complete">
		</form>
	</cfoutput>

	<cfcatch type="any">
		<cfset writeDumpToFile(cfcatch)>
	</cfcatch>
</cftry>
