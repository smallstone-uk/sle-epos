<cftry>
<!DOCTYPE html>
<html>
<head>
<title>EPOS Transactions</title>
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<link href="css/epos_tran.css" rel="stylesheet" type="text/css">
<script src="../scripts/jquery-1.11.1.min.js"></script>
<script src="../scripts/jquery-ui.js"></script>
<script src="js/epos.js"></script>
</head>

<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset trans = epos.LoadTransactions(parm)>
<cfdump var="#trans#" label="trans" expand="no">

<cfoutput>
	<body>
		<script>
			$(document).ready(function(e) {
			});
		</script>
		<div class="content">
			<ul>
				<cfloop array="#trans#" index="item">
					<li class="tran_item">
						<div class="top">
							<h1>#item.timestamp#</h1>
							<h2>#item.employee#</h2>
						</div>
						<div class="left">
							<h2>Net: #item.net#</h2>
							<h2>VAT: #item.vat#</h2>
						</div>
						<div class="right">
							<h2>Status: #item.status#</h2>
							<h2>Mode: #UCase(item.mode)#</h2>
						</div>
						<div class="content">
							<table width="75%" border="1" style="margin:0 auto;">
								<tr>
									<th align="left">Product</th>
									<th align="left">Publication</th>
									<th>Type</th>
									<th>Account</th>
									<th align="right">Qty</th>
									<th align="right">Net</th>
									<th align="right">Discount</th>
									<th align="right">VAT</th>
								</tr>
								<cfloop array="#item.items#" index="i">
									<tr>
										<td align="left">#i.product#</td>
										<td align="left">#i.publication#</td>
										<td align="center">#i.type#</td>
										<td align="center">#i.account#</td>
										<td align="right">#i.qty#</td>
										<td align="right">#i.net#</td>
										<td align="right">#i.discount#</td>
										<td align="right">#i.vat#</td>
									</tr>
								</cfloop>
							</table>
						</div>
					</li>
				</cfloop>
			</ul>
		</div>
	</body>
</cfoutput>
</html>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>