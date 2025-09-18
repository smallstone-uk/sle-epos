<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<link rel="stylesheet" type="text/css" href="css/jquery-ui.css">
	<title>Day Report 3</title>
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
			//	console.log($('#account-form').serialize());
				$.ajax({
					type: "POST",
					url: "ajax/saveDaySheetData3.cfm",
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

<cfobject component="code/epos15" name="ecfc">
<cfobject component="code/reports" name="rep">
<cfflush interval="20">
<cfsetting requesttimeout="900">

<cfoutput>
	<cfset parm = {}>
	<cfset parm.form = form>
	<cfset parm.datasource = application.site.datasource1>
	<cfset parm.url = application.site.normal>
	<cfset parm.grossMode = StructKeyExists(form,"grossMode")>
	<cfset dates = ecfc.GetDates(parm)>
	<cfif StructKeyExists(form,"reportDateFrom")>
		<cfset parm.reportDateFrom = reportDateFrom>
	<cfelseif StructKeyExists(session,"till")>
		<cfset parm.reportDateFrom = session.till.prefs.reportDate>
	<cfelse>
		<cfset parm.reportDateFrom = Now()>
	</cfif>
	<cfset parm.reportDateTo = Now()>

	<body>
		<div>
			<form method="post" enctype="multipart/form-data" id="account-form">
				Report Date:
				<select name="reportDateFrom" id="reportDate">
					<option value="">Select date...</option>
					<cfloop array="#dates.recs#" index="item">
					<option value="#item.value#" <cfif parm.reportDateFrom eq item.value> selected</cfif>>#item.title#</option>
					</cfloop>
				</select>
				<input type="checkbox" name="fixTotals" value="1" />Repair Till Totals?
				<input type="checkbox" name="grossMode" value="1" <cfif parm.grossMode> checked="checked"</cfif> />Gross Mode?
				<input type="submit" name="btnGo" value="Go">
			</form>
		</div>
		
		<cfif StructKeyExists(form,"reportDateFrom")>
			<cfset parm.tranID = rep.LoadTransaction(parm)>
			<cfset data1 = rep.LoadData(parm)>
			<!---<cfdump var="#data1#" label="data1" expand="false">--->
			<cfif !StructKeyExists(data1,"EPOSData")>
				No Sales data found.
			<cfelse>
				<cfset keys = ListSort(StructKeyList(data1.EPOSData,","),"text","asc")>
				<div id="xreading5" class="totalPanel">
					<div class="header">Gross Totals by Group  #DateFormat(reportDateFrom,'ddd dd-mmm-yyyy')#</div>
					<table class="tableList" border="1">
						<tr>
							<th>CODE</th>
							<th>DESCRIPTION</th>
							<th>Markup</th>
							<th>POR</th>
							<th>Items</th>
							<th>Class</th>
							<th width="70" align="right">DR</th>
							<th width="70" align="right">CR</th>
							<th width="70" align="right">Sales<br />VAT</th>
							<th width="70" align="right">Trade</th>
							<th width="70" align="right">Profit</th>
							<th width="70" align="right">POR%</th>
						</tr>
						
						<cfloop list="#keys#" index="key" delimiters=",">
							<cfset item = StructFind(data1.EPOSData,key)>
							<tr>
								<td>#item.pgNomGroup#</td>
								<td>#item.nomTitle#</td>
								<td align="right"><cfif item.pgTarget neq 0>#item.pgTarget#%</cfif></td>
								<td align="right"><cfif item.targetPOR neq 0>#DecimalFormat(item.targetPOR)#%</cfif></td>
								<td align="right">#item.count#</td>
								<td align="right">#item.class#</td>
								<td align="right"><cfif item.drValue neq 0>#DecimalFormat(item.drValue)#</cfif></td>
								<td align="right"><cfif item.crValue neq 0>#DecimalFormat(item.crValue * -1)#</cfif></td>
								<td align="right"><cfif item.vat neq 0>#DecimalFormat(item.vat * -1)#</cfif></td>
								<td align="right"><cfif item.trade neq 0>#DecimalFormat(item.trade)#</cfif></td>
								<td align="right"><cfif item.actualProfit neq 0>#DecimalFormat(item.actualProfit)#</cfif></td>
								<td align="right" class="#item.cellClass#"><cfif item.actualPOR neq 0>#DecimalFormat(item.actualPOR)#%</cfif></td>
							</tr>
						</cfloop>
						<cfif !parm.grossMode>
							<tr>
								<td></td>
								<td>Sales VAT Total</td>
								<td align="right"></td>
								<td align="right"></td>
								<td align="right"></td>
								<td align="right"></td>
								<td align="right"></td>
								<td align="right">#DecimalFormat(data1.totals.vatTotal)#</td>
								<td align="right"></td>
								<td align="right"></td>
								<td align="right"></td>
								<td align="right" class="#item.cellClass#"></td>
							</tr>
						</cfif>
						<cfif !parm.grossMode>
							<cfset crTotal = data1.totals.crTotal + data1.totals.vatTotal>
						<cfelse>
							<cfset crTotal = data1.totals.crTotal>
						</cfif>
						
						<tr>
							<th align="center" colspan="5">
								<cfset errorValue = ABS(data1.totals.drTotal - crTotal)>
								<cfif errorValue lt 0.009>
									<input type="button" id="btnSave" value="Save Transaction" />
								<cfelse>
									Daysheet does not balance. Please correct.
								</cfif>
							</th> 
							<th align="right">Balance</th>
							<th align="right">#DecimalFormat(data1.totals.drTotal)#</th>
							<th align="right">#DecimalFormat(crTotal)#</th>
							<th align="right">#DecimalFormat(data1.totals.vatTotal)#</th>
							<th align="right"><cfif errorValue>Error: </cfif></th>
							<th align="right">#DecimalFormat(errorValue)#</th>
							<th align="right"></th>
						</tr>
						<tr>
							<th align="center" colspan="5">
								<cfif !StructKeyExists(data1,"nomItems")>
									Sales transaction does not exist. Click Save Transaction.
								<cfelse>
									Transaction ID: <a href="#application.site.url1#salesMain3.cfm?acc=1&tran=#parm.tranID#" target="#parm.tranID#">#parm.tranID#</a>
								</cfif>
							</th> 
							<cfif !parm.grossMode>
								<th align="right" colspan="2">Shop Totals</th>
								<th align="right">#DecimalFormat(data1.totals.saleTotal)#</th>
								<th align="right"></th>
								<th align="right">#DecimalFormat(data1.totals.tradeTotal)#</th>
								<th align="right">#DecimalFormat(data1.totals.profittotal)#</th>
								<th align="right">#DecimalFormat((data1.totals.profittotal / data1.totals.saleTotal) * 100)#%</th>
							<cfelse>
								<th colspan="7"></th>
							</cfif>
						</tr>
					</table>
				</div>
			</cfif>
		</cfif>
		<div id="loading">loading</div>
		<div id="postData">postData</div>
	</body>
</cfoutput>
</html>
