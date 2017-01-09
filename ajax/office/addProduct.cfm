<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var isNew = false;
			
			$('input[name="title"], input[name="unitsize"]').virtualKeyboard();
			$('input[name="ourprice"], input[name="quantity"]').virtualNumpad();
			$('input[name="expirydate"]').virtualDate();
			$('input[name="title"]').booleanResponse("ajax/checkProductExistsByTitle.cfm", isNew);
			
			$('input[name="tradeprice"]').virtualNumpad(null, {
				keypress: function() {
					$('input[name="ourprice"]').val( nf($('input[name="tradeprice"]').val() * 1.2, "str") );
				}
			});
			
			$('.barcodebox').barcodeBox(function(barcode) {
				$.ajax({
					type: "POST",
					url: "ajax/checkBarcodeExists.cfm",
					data: {"barcode": barcode},
					success: function(data) {
						var result = data.toJava();
						console.log(result);
						
						if (result.signal) {
							isNew = false;
							$('.barcodemsg').html("Product already exists. You can update it below.");
							$('input[name="title"]').val(result.prodtitle);
							$('input[name="tradeprice"]').val( nf(result.produnittrade, "str") );
							$('input[name="ourprice"]').val( nf(result.siOurprice, "str") );
							$('input[name="unitsize"]').val(result.produnitsize);
						} else {
							isNew = true;
							$('##AddProductForm')[0].reset();
							$('.barcodemsg').html("Product does not exist. Create it below.");
							$('input[name="title"]').focus();
						}
					}
				});
			});
			
			$('##AddProductForm').submit(function(event) {
				$.ajax({
					type: "POST",
					url: "ajax/postProductForm.cfm",
					data: {
						"product_form": $('##AddProductForm').serialize(),
						"isNew": isNew
					},
					beforeSend: function() {
						$('input[type="submit"]').prop("disabled", true);
					},
					success: function(data) {
						var result = data.toJava();
						$('input[type="submit"]').prop("disabled", true);
					}
				});
				event.preventDefault();
			});
		});
	</script>
	<div class="sandbox center">
		<form method="post" enctype="multipart/form-data" id="AddProductForm">
			<label>
				<span class="barcodebox">Click to scan barcode</span>
				<span class="barcodemsg"></span>
			</label>
			<label>
				<span>Product title</span>
				<input type="text" name="title" placeholder="Eg. Apples" value="Test">
			</label>
			<label>
				<span>Unit size/weight</span>
				<input type="text" name="unitsize" placeholder="Eg. 200g" value="Test">
			</label>
			<label>
				<span>Expiry date</span>
				<input type="text" name="expirydate" placeholder="Eg. 01/05/2015" data-past="false" value="15/02/2020">
			</label>
			<label>
				<span>Trade price (per unit)</span>
				<input type="text" name="tradeprice" placeholder="Eg. 1.29" value="1.29">
			</label>
			<label>
				<span>Our price (per unit)</span>
				<input type="text" name="ourprice" placeholder="Eg. 1.55" value="1.55">
			</label>
			<label>
				<span>Quantity (total units)</span>
				<input type="text" name="quantity" placeholder="Eg. 36" data-wholenumber="true" value="36">
			</label>
			<label>
				<input type="submit" value="Continue">
			</label>
		</form>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>