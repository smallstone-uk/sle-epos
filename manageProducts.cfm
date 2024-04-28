<cftry>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<link href="css/epos.css" rel="stylesheet" type="text/css">
<link href="css/virtualInput.css" rel="stylesheet" type="text/css">
<script src="../scripts/jquery-1.11.1.min.js"></script>
<script src="../scripts/jquery-ui.js"></script>
<script src="../scripts/jquery-barcode.js"></script>
<script src="js/epos.js"></script>
<script src="js/virtualInput.js"></script>

<cfoutput>
	<style>
		body {background:white;}
		.sandbox_title {float:left;font-size:24px;width:100%;margin:10px;text-align:center;}
		.sandbox_subtitle {float:left;font-size:18px;width:100%;margin:10px;text-align:center;}
		input {margin: 0 5px 0 5px !important;border: none !important;border-bottom: 1px solid ##DDD !important;padding: 0 !important;font-size: 17px !important;height: 35px !important;}
		input:focus {border: none !important;border-bottom: 1px solid ##4C9EFC !important;}
		input:focus::-webkit-input-placeholder {color: ##0077FF;}
		input:focus::-webkit-input-placeholder {color: ##4C9EFC;}
		label {float: left;width: 500px;margin:15px 0;}
		label span {float: left;width: 100%;margin: 5px 5px 0 5px;font-size: 20px;color: ##0077FF;padding-top: 5px;}
		input[type="submit"] {float: left;height: 60px !important;text-align: center;margin: 0 5px 0 5px !important;border: none !important;background: ##0077FF;font-size: 18px !important;padding: 0 30px !important;outline: 0;cursor: pointer;color: ##FFF;width: 100%;}
		input[type="submit"]:active {color: ##FFF;background: ##222;}
		.VIC_ErrorFld, .VIC_ErrorFld:focus {border: none !important;border-bottom: 1px solid ##C00 !important;}
		.barcodemsg {text-align: center;font-size: 16px;}
	</style>
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
						console.log('barcode '+result);
						
						if (result.signal) {
							isNew = false;
							$('.barcodemsg').html("Product already exists. You can update it below.");
							$('input[name="title"]').val(result.prodtitle);
							$('input[name="tradeprice"]').val( nf(result.produnittrade, "str") );
							$('input[name="ourprice"]').val( nf(result.siOurprice, "str") );
							$('input[name="unitsize"]').val(result.produnitsize);	// TODO should be siUnitSize
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
				
				event.preventDefault();
			});
		});
	</script>
	<div class="center" style="width:900px;">
		<form method="post" enctype="multipart/form-data" id="AddProductForm">
			<label>
				<span class="barcodebox">Click to scan barcode</span>
				<span class="barcodemsg"></span>
			</label>
			
			<label>
				<span>Product title</span>
				<input type="text" name="title" placeholder="Eg. Apples">
			</label>
			
			<label>
				<span>Trade price (per unit)</span>
				<input type="text" name="tradeprice" placeholder="Eg. 1.29">
			</label>
			
			<label>
				<span>Our price (per unit)</span>
				<input type="text" name="ourprice" placeholder="Eg. 1.55">
			</label>
			
			<label>
				<span>Unit size/weight</span>
				<input type="text" name="unitsize" placeholder="Eg. 200g">
			</label>
			
			<label>
				<span>Expiry date</span>
				<input type="text" name="expirydate" placeholder="Eg. 01/05/2015" data-past="false">
			</label>
			
			<label>
				<span>Quantity (total units)</span>
				<input type="text" name="quantity" placeholder="Eg. 36" data-wholenumber="true">
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