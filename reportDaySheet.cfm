<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<script src="js/jquery-1.11.1.min.js"></script>
	<title>Day Report</title>
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
		});
	</script>
</head>
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfobject component="code/epos" name="ep">
<cfset dates = ecfc.GetDates(parm)>
<cfif StructKeyExists(session,"till")>
	<cfset parm.reportDate = session.till.prefs.reportDate>
	<cfelse>
	<cfset parm.reportDate = Now()>
</cfif>
<cfif StructKeyExists(form,"reportDate")>
	<cfset parm.reportDate = form.reportDate>
	<cfset epos = ecfc.LoadEPOSTotals(parm)>
	<!---<cfdump var="#epos#" label="epos" expand="true">--->
	<cfquery name="QItemSum2" datasource="#parm.datasource#">
		SELECT pcatGroup, prodCatID,prodEposCatID, eiClass, eiType, pgTitle, pgNomGroup, nomTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, Count(*) AS itemCount
		FROM `tblEPOS_Items`
		INNER JOIN tblEPOS_Header ON ehID = eiParent
		INNER JOIN tblProducts ON prodID = eiProdID
		INNER JOIN tblProductCats ON pcatID = prodCatID
		INNER JOIN tblProductGroups ON pgID = pcatGroup
		INNER JOIN tblNominal ON pgNomGroup = nomCode
		WHERE DATE( ehTimeStamp ) = '#form.reportDate#'
		GROUP by pgNomGroup
	</cfquery>
	<!---<cfdump var="#QItemSum2#" label="QItemSum2" expand="false">--->
	
	<cfquery name="QItemSummary" datasource="#parm.datasource#">
		SELECT pcatGroup, prodCatID,prodEposCatID, eiClass, eiType, pgTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, Count(*) AS itemCount
		FROM `tblEPOS_Items`
		INNER JOIN tblEPOS_Header ON ehID = eiParent
		INNER JOIN tblProducts ON prodID = eiProdID
		INNER JOIN tblProductCats ON pcatID = prodCatID
		INNER JOIN tblProductGroups ON pgID = pcatGroup
		WHERE DATE( ehTimeStamp ) = '#form.reportDate#'
		GROUP by eiClass, eiType, pgTitle,prodEposCatID
	</cfquery>
	<!---<cfdump var="#QItemSummary#" label="QItemSummary" expand="false">--->
	<cfquery name="QCashback" datasource="#parm.datasource#">
		SELECT SUM(ehCashback) AS total
		FROM tblEPOS_Header
		WHERE DATE( ehTimeStamp ) = '#form.reportDate#'
	</cfquery>
	<cfquery name="QDayHeader" datasource="#parm.datasource#">
		SELECT *
		FROM tblepos_dayheader
		WHERE DATE( dhTimeStamp ) = '#form.reportDate#'
	</cfquery>
	<cfset today = ep.QueryToStruct(QDayHeader)>	
</cfif>

	<cffunction name="GetTotal" access="public" returntype="numeric">
		<cfargument name="data" type="struct" required="yes">
		<cfargument name="key" type="string" required="yes">
		<cfset var result=0>
		
		<cfif StructKeyExists(data,key)>
			<cfset result = StructFind(data,key)>
		</cfif>
		<cfreturn result>
	</cffunction>
	

<body>
<cfoutput>
<div>
	<form method="post" enctype="multipart/form-data">
		Report Date:
		<select name="reportDate" id="reportDate">
			<option value="">Select date...</option>
			<cfloop array="#dates.recs#" index="item">
			<option value="#item.value#" <cfif parm.reportDate eq item.value> selected</cfif>>#item.title#</option>
			</cfloop>
		</select>
		<input type="submit" name="btnGo" value="Go">
	</form>
</div>
<cfif StructKeyExists(form,"reportDate")>
	<div id="xreading3" class="totalPanel">
		<div class="header">Shop Daysheet Summary</div>
		<table width="500" class="tableList" border="1">
			<tr>
				<th>Group</th>
				<th>Title</th>
				<th>Class</th>
				<th>Type</th>
				<th align="right">DR</th>
				<th align="right">CR</th>
				<th align="right">Count</th>
			</tr>
			<cfset crtotal = 0>
			<cfset drtotal = 0>
			<cfset vatTotal = 0>
			<cfset countTotal = 0>
			<cfloop query="QItemSummary">
				<cfset countTotal += itemCount>
				<cfset vatTotal += vat>
				<cfset gross = net + vat>
				<cfif gross gt 0>
					<cfset drtotal += gross>
					<cfelse>
					<cfset crtotal += gross>
				</cfif>
				<tr>
					<td>#pcatGroup#</td>
					<td>#pgTitle#</td>
					<td>#eiClass#</td>
					<td>#eiType#</td>
					<td align="right"><cfif gross gt 0>
							#DecimalFormat(net)#
						</cfif></td>
					<td align="right"><cfif gross lt 0>
							#DecimalFormat(-net)#
						</cfif></td>
					<td align="right">#itemCount#</td>
				</tr>
			</cfloop>
			<tr>
				<td></td>
				<td>SALES VAT TOTAL</td>
				<td></td>
				<td></td>
				<td align="right"><cfif vatTotal gt 0>
						#DecimalFormat(vatTotal)#
					</cfif></td>
				<td align="right"><cfif vatTotal lt 0>
						#DecimalFormat(-vatTotal)#
					</cfif></td>
				<td></td>
			</tr>
			<tr>
				<th align="right" colspan="4">Totals</th>
				<th align="right">#DecimalFormat(drtotal)#</th>
				<th align="right">#DecimalFormat(-crtotal)#</th>
				<th align="right">#countTotal#</th>
			</tr>
			<cfif abs(drtotal + crtotal) gt 0.001>
				<tr>
					<th align="right" colspan="4">Error</th>
					<th></th>
					<th align="right">#DecimalFormat(drtotal + crtotal)#</th>
					<th></th>
				</tr>
			</cfif>
		</table>
	</div>
	<div id="xreading4" class="totalPanel">
		<div class="header">Till Totals</div>
		<table class="tableList" border="1">
			<tr>
				<th>DESCRIPTION</th>
				<th width="70" align="right">DR</th>
				<th width="70" align="right">CR</th>
			</tr>
			<cfset drTotal = 0>
			<cfset crTotal = 0>
			<cfset loopcount = 0>
			<cfset keys = ListSort(StructKeyList(epos.accounts,","),"text","ASC",",")>
			<cfloop list="#keys#" index="fld">
			<tr>
				<td>#fld#</td>
				<td align="right"><cfif epos.accounts[fld] gt 0>
						<cfset drTotal += epos.accounts[fld]>
						#DecimalFormat(epos.accounts[fld])#
					</cfif></td>
				<td align="right"><cfif epos.accounts[fld] lt 0>
						<cfset crTotal -= epos.accounts[fld]>
						#DecimalFormat(epos.accounts[fld] * -1)#
					</cfif></td>
			</tr>
			</cfloop>
			<tr>
				<td><strong>Totals</strong></td>
				<td align="right"><strong>#DecimalFormat(drTotal)#</strong></td>
				<td align="right"><strong>#DecimalFormat(crTotal)#</strong></td>
			</tr>
		</table>
	</div>
	<cfif NOT StructIsEmpty(epos.accounts)>
	<div id="xreading5" class="totalPanel">
		<div class="header">Gross Totals by Group</div>
		<table class="tableList" border="1">
			<tr>
				<th>CODE</th>
				<th>DESCRIPTION</th>
				<th width="70" align="right">DR</th>
				<th width="70" align="right">CR</th>
			</tr>
			<cfset drTotal = 0>
			<cfset crTotal = 0>
			<cfloop query="QItemSum2">
				<cfset drValue = 0>
				<cfset crValue = 0>
				<cfset gross = net + vat>
				<cfif Find(eiClass,"supp,pay")>
					<cfset drValue = gross>
					<cfset drTotal += gross>
				<cfelseif Find(eiClass,"sale,item")>
					<cfif eiType eq 'VOUCHER'>
						<cfset drValue = gross>
						<cfset drTotal += gross>
					<cfelse>
						<cfset crValue = gross>
						<cfset crTotal -= gross>
					</cfif>
				</cfif>
				<tr>
					<td>#pgNomGroup#</td>
					<td>#nomTitle#</td>
					<td align="right"><cfif drValue neq 0>#DecimalFormat(drValue)#</cfif></td>
					<td align="right"><cfif crValue neq 0>#DecimalFormat(crValue * -1)#</cfif></td>
				</tr>
			</cfloop>
			<tr>
				<th align="right" colspan="2">Totals</th>
				<th align="right">#DecimalFormat(drtotal)#</th>
				<th align="right">#DecimalFormat(crtotal)#</th>
			</tr>
			<tr>
				<td colspan="3">Cash in Drawer:</td>
				<td align="right">#GetTotal(epos.accounts,"cashindw")#</td>
			</tr>
			<tr>
				<td colspan="3">Suppliers Paid:</td>
				<td align="right">#GetTotal(epos.accounts,"supplier")#</td>
			</tr>
			<tr>
				<td colspan="3">Cashback:</td>
				<td align="right">#DecimalFormat(val(QCashback.total))#</td>
			</tr>
			<tr>
				<td colspan="3">Card Sales:</td>
				<td align="right">#DecimalFormat(epos.accounts.cardindw) - val(QCashback.total)#</td>
			</tr>
			<tr>
				<td colspan="3">Less float:</td>
				<td align="right">#GetTotal(epos.accounts,"float")#</td>
			</tr>
			<cfset cashTaken = GetTotal(epos.accounts,"cashindw") + GetTotal(epos.accounts,"supplier") + GetTotal(epos.accounts,"float") + val(QCashback.total)>
			<tr>
				<td colspan="3"><strong>Cash Taken:</strong></td>
				<td align="right"><strong>#DecimalFormat(cashTaken)#</strong></td>
			</tr>
		</table>
	</div>
	</cfif>
	
		<cfif !StructIsEmpty(today)>
			<cfset noteTotal = 0>
			<cfset coinTotal = 0>
			<cfset poundArray = [50,20,10,5,2,1]>
			<div id="xreading6" class="totalPanel">
				<div class="header">Cash Counted</div>
				<table class="tableList" border="1">
					<tr>
						<th>Denomination</th>
						<th>Value</th>
					</tr>
					<cfloop array="#poundArray#" index="denom">
						<cfset dataMOD = denom * 100>
						<cfset poundFld = "dhcid_#NumberFormat(dataMOD,'0000')#">
						<cfset value = StructFind(today,poundFld)>
						<cfif denom lt 5>
							<cfset coinTotal += value>
						<cfelse>
							<cfset noteTotal += value>
						</cfif>
						<tr>
							<td>&pound;#denom#</td>
							<td align="right">#value#</td>
						</tr>
					</cfloop>
					<cfloop array="#poundArray#" index="denom">
						<cfset penceFld = "dhcid_#NumberFormat(denom,'0000')#">
						<cfset value = StructFind(today,penceFld)>
						<cfset coinTotal += value>
						<tr>
							<td>#denom#p</td>
							<td align="right">#value#</td>
						</tr>
					</cfloop>
					<tr>
						<td>Coin Total</td>
						<td align="right">#DecimalFormat(coinTotal)#</td>
					</tr>
					<tr>
						<td>Note Total</td>
						<td align="right">#DecimalFormat(noteTotal)#</td>
					</tr>
					<tr>
						<td>Cash Total</td>
						<td align="right">#DecimalFormat(noteTotal + coinTotal)#</td>
					</tr>
					<tr>
						<td>Difference</td>
						<td align="right">#DecimalFormat(noteTotal + coinTotal - GetTotal(epos.accounts,"cashindw"))#</td>
					</tr>
				</table>
			</div>
		</cfif>

	<div style="clear:both"></div>
	<div class="totalPanel">
		<div class="header">Tran Dump</div>
		<cfset parm = {}>
		<cfset parm.reportDate = form.reportDate>
		<cfset ecfc.DumpTrans(parm)>
	</div>
	<div style="clear:both"></div>
</cfif>
</cfoutput>
</body>
</html>