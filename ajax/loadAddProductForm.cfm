<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<script>
		$(document).ready(function(e) {
			$('input[name="tradeprice"]').change(function(event) {
				var value = nf($(this).val(), "num");
				var markup = value * 0.2;
				var ourprice = value + markup;
				$('input[name="ourprice"]').val(nf(ourprice, "str"));
			});
			$('input[name="title"]').virtualKeyboard({});
			$('input[name="weight"]').virtualKeyboard({});
			$('input[name="tradeprice"]').focus(function(event) {
				$.virtualNumpad({
					callback: function(value) {
						$('input[name="tradeprice"]').val(value);
						var markup = value * 0.2;
						var ourprice = value + markup;
						$('input[name="ourprice"]').val(nf(ourprice, "str"));
					}
				});
			});
			$('input[name="ourprice"]').focus(function(event) {
				$.virtualNumpad({
					callback: function(value) {
						$('input[name="ourprice"]').val(value);
					}
				});
			});
		});
	</script>
	<form method="post" enctype="multipart/form-data" id="AddProductForm">
		<input type="text" id="apf_title" name="title" placeholder="Product Title" />
		<input type="text" id="apf_weight" name="weight" placeholder="Product Weight (450g)" />
		<input type="text" id="apf_tradeprice" name="tradeprice" placeholder="Unit Trade Price" style="width: 235px;margin-right: 0;" />
		<input type="text" id="apf_ourprice" name="ourprice" placeholder="Our Price" style="width: 235px;margin-right: 0;" />
		<input type="submit" name="submit" value="Continue" />
	</form>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="no">
</cfcatch>
</cftry>