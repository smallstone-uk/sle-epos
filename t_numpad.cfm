<div class="till_numpad">
	<script>
		$(document).ready(function(e) {
			var decimal = "";
			$('.till_numpad .tn_digits span').click(function(event) {
				decimal += $(this).html();
				$('.tn_value').html( tillFormat(decimal) );
			});
			$('.till_numpad .tn_digits span[data-method="clear"]').click(function(event) {
				$('.tn_value').html("");
				decimal = "";
			});
			$('.payment_selector').bigSelect({
				height: 55,
				callback: function(value) {
					console.log(value);
				}
			});
		});
	</script>
	<select class="payment_selector" data-style="text-transform:uppercase;width: 115px;margin:0;">
		<option value="cash">Cash</option>
		<option value="card">Card</option>
		<option value="cheque">Cheque</option>
		<option value="voucher">Voucher</option>
		<option value="owners">Owners</option>
	</select>
	<span class="tn_value"></span>
	<div class="tn_digits">
		<span></span>
		<span>7</span>
		<span>8</span>
		<span>9</span>
		<span>4</span>
		<span>5</span>
		<span>6</span>
		<span>1</span>
		<span>2</span>
		<span>3</span>
		<span>0</span>
		<span>00</span>
		<span data-method="clear">C</span>
	</div>
	
	<span class="tn_enter" data-method="enter">Enter</span>
</div>