<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<link rel="stylesheet" type="text/css" href="css/jquery-ui.css">
	<title>Day Report</title>
	<script src="common/scripts/common.js"></script>
	<script src="js/jquery-1.11.1.min.js"></script>
	<script src="js/jquery-ui-1.10.3.custom.min.js"></script>
	<script src="js/jquery.dcmegamenu.1.3.3.js"></script>
	<script src="js/accounts.js" type="text/javascript"></script>

	<script type="text/javascript">
		$(document).ready(function() {
			$('#quicksearch').on("keyup",function() {
				var srch=$(this).val();
				var hidetotals = false;
				$('.searchrow').each(function() {
					var id=$(this).attr("data-prodID");
					var str=$(this).attr("data-title");
					
					if (str.toLowerCase().indexOf(srch.toLowerCase()) == -1) {
						$(this).hide();
						hidetotals = true;
					} else {
						$(this).show();
					}
					
				});
				if (hidetotals) $('#pagetotals').hide()
					else $('#pagetotals').show();
			});
			$('#btnSave').click(function(event) {
				$('#postData').html("loading...");
				$.ajax({
					type: "POST",
					url: "ajax/saveDaySheetData.cfm",
					data : $('#account-form').serialize(),
					beforeSend: function() {
						$('#loading').loading(true);
						$('#postData').html("");
					},
					success: function(data) {
						$('#postData').html(data).show();
						$('#loading').loading(false);
					}
				});
				event.preventDefault();
			});
		});

	</script>
	<style type="text/css">
		#loading {border:solid 1px #F00; padding:4px; float:left}
		#postData {border:solid 1px #ccc; padding:4px; float:left}
		#xreading5 {border:solid 1px #ccc; padding:4px; float:left}
		.porGood {background-color:#00FF33;}
		.porBad {background-color:#F00;}
		.porNone {background-color:#FFF;}
		.porNear {background-color:#F90;}
	</style>
</head>
<body>
<cfobject component="code/epos15" name="ecfc">
<cfobject component="code/epos" name="ep">
<cfflush interval="20">
<cfsetting requesttimeout="900">
<cfoutput>
	<cfset parm = {}>
	<cfset parm.datasource = application.site.datasource1>
	<cfset parm.url = application.site.normal>
	<cfset dates = ecfc.GetDates(parm)>
	<cfif StructKeyExists(session,"till")>
		<cfset parm.reportDateFrom = session.till.prefs.reportDate>
	<cfelse>
		<cfset parm.reportDateFrom = Now()>
	</cfif>
	<cfset parm.reportDateTo = Now()>
	<cfif StructKeyExists(form,"reportDateFrom")>
		<p>Starting the report...</p>
		<cfset sysTime = GetTickCount()>
		<cfset parm.reportDateFrom = form.reportDateFrom>
		<cfset epos = ecfc.LoadEPOSTotals(parm)>
		<cfset tickNow = GetTickCount()>
		<p>#tickNow - sysTime#ms Load EPOS totals...</p>
		<cfset endofDay = DateFormat(DateAdd("d",1,form.reportDateFrom),"yyyy-mm-dd")>
		<cfset sysTime = GetTickCount()>
		<cfquery name="QItemSum2" datasource="#parm.datasource#">
			SELECT pcatGroup, prodCatID,prodEposCatID, eiClass,eiType, pgTitle,pgNomGroup,pgTarget, nomTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, SUM(eiTrade) AS trade, Count(*) AS itemCount
			FROM `tblEPOS_Items`
			INNER JOIN tblEPOS_Header ON ehID = eiParent
			INNER JOIN tblProducts ON prodID = eiProdID
			INNER JOIN tblProductCats ON pcatID = prodCatID
			INNER JOIN tblProductGroups ON pgID = pcatGroup
			INNER JOIN tblNominal ON pgNomGroup = nomCode
			WHERE ehTimeStamp > '#form.reportDateFrom#'
			AND ehTimeStamp < '#endofDay#'
			GROUP by pgNomGroup
		</cfquery>
		<cfset tickNow = GetTickCount()>
		<p>#tickNow - sysTime#ms Load group summary...</p>
		<!---<cfdump var="#QItemSum2#" label="QItemSum2" expand="false">--->
	</cfif>
	<div>
		<form method="post" enctype="multipart/form-data" id="account-form">
			Report Date:
			<select name="reportDateFrom" id="reportDate">
				<option value="">Select date...</option>
				<cfloop array="#dates.recs#" index="item">
				<option value="#item.value#" <cfif parm.reportDateFrom eq item.value> selected</cfif>>#item.title#</option>
				</cfloop>
			</select>
			<input type="checkbox" name="fixTotals" value="1" />Repair Till Totals
			<input type="submit" name="btnGo" value="Go">
		</form>
	</div>
	<cfif StructKeyExists(form,"reportDateFrom")>
		<div id="xreading5" class="totalPanel">
			<div class="header">Gross Totals by Group  #DateFormat(reportDateFrom,'ddd dd-mmm-yyyy')#</div>
			<table class="tableList" border="1">
				<tr>
					<th>CODE</th>
					<th>DESCRIPTION</th>
					<th>Markup</th>
					<th>POR</th>
					<th>Items</th>
					<th width="70" align="right">DR</th>
					<th width="70" align="right">CR</th>
					<th width="70" align="right">Sales<br />VAT</th>
					<th width="70" align="right">Trade</th>
					<th width="70" align="right">Profit</th>
					<th width="70" align="right">POR%</th>
				</tr>
				<cfset drTotal = 0>
				<cfset crTotal = 0>
				<cfset vatTotal = 0>
				<cfset tradeTotal = 0>
				<cfset profitTotal = 0>
				<cfset netSales = 0>
				<cfloop query="QItemSum2">
					<cfset drValue = 0>
					<cfset crValue = 0>
					<cfset vatValue = 0>
					<cfset gross = net + vat>
					<cfset profit = 0>
					<cfset POR = 0>
					<cfset trgPOR = 0>
					<cfif Find(eiClass,"supp,pay")>
						<cfif eiType neq 'WASTE'>
							<cfset drValue = gross>
							<cfset drTotal += gross>
						<cfelse>
							<cfset crValue = gross>
							<cfset crTotal -= gross>
						</cfif>
					<cfelseif Find(eiClass,"sale,item")>
						<cfif eiType eq 'VOUCHER'>
							<cfset drValue = gross>
							<cfset drTotal += gross>
						<cfelse>
							<cfset crValue = net>
							<cfset vatValue = vat>
							<cfset crTotal -= net>
							<cfset vatTotal -= vat>
						</cfif>
					</cfif>
					<cfset tradeTotal += trade>
					<cfif eiClass eq 'sale'>
						<cfif pgTarget gt 0>
							<cfset trgRetail = 1 + (pgTarget / 100)>
							<cfset trgProfit = trgRetail - 1>
							<cfset trgPOR = int((trgProfit / trgRetail) * 10000)/100>
						</cfif>
						<cfset netSales -= net>
						<cfset profit = (net + trade) * -1>
						<cfset POR = (profit / -net) * 100>
					</cfif>
					<cfset profitTotal += profit>
					<cfset cellClass = "porNone">
					<cfif POR gt trgPOR>
						<cfset cellClass = "porGood">
					<cfelseif POR lt trgPOR AND trgPOR gt 0>
						<cfset cellClass = "porBad">
						<cfif POR gt (trgPOR * 0.9)>
							<cfset cellClass = "porNear">
						</cfif>
					</cfif>
					<tr>
						<td>#pgNomGroup#</td>
						<td>#nomTitle#</td>
						<td align="right"><cfif pgTarget neq 0>#pgTarget#%</cfif></td>
						<td align="right"><cfif trgPOR neq 0>#trgPOR#%</cfif></td>
						<td align="right">#itemCount#</td>
						<td align="right"><cfif drValue neq 0>#DecimalFormat(drValue)#</cfif></td>
						<td align="right"><cfif crValue neq 0>#DecimalFormat(crValue * -1)#</cfif></td>
						<td align="right"><cfif vatValue neq 0>#DecimalFormat(vatValue * -1)#</cfif></td>
						<td align="right"><cfif trade neq 0>#DecimalFormat(trade)#</cfif></td>
						<td align="right"><cfif profit neq 0>#DecimalFormat(profit)#</cfif></td>
						<td align="right" class="#cellClass#"><cfif POR neq 0>#DecimalFormat(POR)#%</cfif></td>
					</tr>
				</cfloop>
				<tr>
					<th align="center" colspan="4">
						<cfif ABS(drtotal - crtotal - vatTotal) lte 0.01>
							<input type="button" id="btnSave" value="Save Transaction" />
						</cfif>
					</th> 
					<th align="right">Totals</th>
					<th align="right">#DecimalFormat(drTotal)#</th>
					<th align="right">#DecimalFormat(crTotal)#</th>
					<th align="right">#DecimalFormat(vatTotal)#</th>
					<th align="right">#DecimalFormat(tradeTotal)#</th>
					<th align="right">#DecimalFormat(profitTotal)#</th>
					<th align="right">#DecimalFormat((profitTotal / netSales) * 100)#%</th>
				</tr>
				<cfif abs(drtotal - crtotal - vatTotal) gt 0.01>
				<tr>
					<th align="right" colspan="3">Difference</th>
					<th align="right">#DecimalFormat(crtotal - crtotal - vatTotal)#</th>
				</tr>
				</cfif>
			</table>
		</div>
		<div id="loading">loading</div>
		<div id="postData">postData</div>
	</cfif>
</cfoutput>
</body>
</html>