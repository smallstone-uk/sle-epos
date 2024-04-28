<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>

<cfoutput>
	<div style="width:600px;">
		<script>
			$(document).ready(function(e) {
				$('##title').virtualKeyboard({});
				$('.FCDatePicker').FCDatePicker();
				//$('.statusSelectBox, .typeSelectBox').bigSelect({});
				$('##amount').focus(function(event) {
					var obj = $(this);
					$.virtualNumpad({
						callback: function(value) {
							obj.val(value);
						}
					});
				});
				$('##qty').focus(function(event) {
					var obj = $(this);
					$.virtualNumpad({
						wholenumber: true,
						callback: function(value) {
							obj.val(value);
						}
					});
				});
				$('.typeSel').buttonSelect('.typeHiddenFld');
				$('.statusSel').buttonSelect('.statusHiddenFld');
			});
		</script>
		<form method="post" enctype="multipart/form-data" id="AddDealForm">
			<div class="form_row">
				<span><h1>Title</h1></span>
				<span><input type="text" name="title" id="title" placeholder="Deal title" /></span>
			</div>
			<div class="form_row">
				<span>
					<h1>Starts</h1>
					<h1>Ends</h1>
				</span>
				<span><input type="text" name="starts" class="FCDatePicker" id="starts" placeholder="DD/MM/YYYY" /></span>
				<span><input type="text" name="ends" class="FCDatePicker" id="ends" placeholder="DD/MM/YYYY" /></span>
			</div>
			<div class="form_row">
				<span>
					<h1>Quantity</h1>
					<h1>Discount</h1>
				</span>
				<span>
					<input type="hidden" name="type" class="typeHiddenFld" />
					<ul class="button_select typeSel">
						<li data-selected="true">Quantity</li>
						<li>Discount</li>
					</ul>
				</span>
			</div>
			<!---<table width="100%" border="0" class="formTable">
				<tr>
					<td align="right"></td>
				</tr>
				<tbody>
					<table width="100%" border="0" class="formTable">
						<tr>
							<td align="right"><input type="text" name="starts" class="FCDatePicker" id="starts" placeholder="DD/MM/YYYY" /></td>
							<td align="right"><input type="text" name="ends" class="FCDatePicker" id="ends" placeholder="DD/MM/YYYY" /></td>
						</tr>
					</table>
				</tbody>
			</table>
			<table width="100%" border="0" class="formTable">
				<tr>
					<td align="right">
						<input type="hidden" name="type" class="typeHiddenFld" />
						<ul class="button_select typeSel">
							<li data-selected="true">Quantity</li>
							<li>Discount</li>
						</ul>
					</td>
				</tr>
				<tbody>
					<table width="100%" border="0" class="formTable">
						<tr>
							<td align="right"><input type="text" name="amount" id="amount" /></td>
							<td align="right"><input type="text" name="qty" id="qty" /></td>
						</tr>
					</table>
				</tbody>
			</table>
			<table width="100%" border="0" class="formTable">
				<tr>
					<td align="right">
						<input type="hidden" name="status" class="statusHiddenFld" />
						<ul class="button_select statusSel">
							<li data-selected="true">Active</li>
							<li>Inactive</li>
						</ul>
					</td>
				</tr>
			</table>--->
		</form>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>