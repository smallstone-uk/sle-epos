<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="css/tillshell.css">
	<link rel="stylesheet" type="text/css" href="css/jquery-ui.css">
	<title>Day Report</title>
	<script src="js/jquery-1.11.1.min.js"></script>
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
<cfsetting requesttimeout="900">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfobject component="#application.site.codePath#" name="ecfc">
<cfobject component="code/epos" name="ep">
<cfset dates = ecfc.GetDates(parm)>
<cfif StructKeyExists(session,"till")>
	<cfset parm.reportDateFrom = session.till.prefs.reportDate>
<cfelse>
	<cfset parm.reportDateFrom = Now()>
</cfif>
<cfset parm.reportDateTo = Now()>
<cfif StructKeyExists(form,"reportDateFrom")>
	<cfflush interval="20">
	<p>Starting the report...</p>
	<cfoutput>
		<cfset sysTime = GetTickCount()>
		<cfset parm.reportDateFrom = form.reportDateFrom>
		<cfset epos = ecfc.LoadEPOSTotals(parm)>
		<cfset endofDay = DateFormat(DateAdd("d",1,form.reportDateFrom),"yyyy-mm-dd")>
		<cfset tickNow = GetTickCount()>
		<p>#tickNow - sysTime#ms Load EPOS totals...</p>
		<!---<cfdump var="#epos#" label="epos" expand="true">--->
		
		<cfset sysTime = GetTickCount()>
		<cfquery name="QItemSum2" datasource="#parm.datasource#">
			SELECT pcatGroup, prodCatID,prodEposCatID, eiClass,eiType, pgTitle,pgNomGroup, nomTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat, Count(*) AS itemCount
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
		
		<cfset sysTime = GetTickCount()>
		<cfquery name="QItemSummary" datasource="#parm.datasource#">
			SELECT pgTitle, pcatGroup, prodTitle,prodID,prodCatID,prodEposCatID, pgNomGroup, eiClass, eiType, SUM(eiQty) AS qty, SUM(eiNet) AS net, SUM(eiVAT) as vat, Count(*) AS itemCount
			FROM `tblEPOS_Items`
			INNER JOIN tblEPOS_Header ON ehID = eiParent
			INNER JOIN tblProducts ON prodID = eiProdID
			INNER JOIN tblProductCats ON pcatID = prodCatID
			INNER JOIN tblProductGroups ON pgID = pcatGroup
			WHERE ehTimeStamp > '#form.reportDateFrom#'
			AND ehTimeStamp < '#endofDay#'
			GROUP by eiClass, eiType, pgTitle <!---,prodEposCatID--->
		</cfquery>
		<cfset tickNow = GetTickCount()>
		<p>#tickNow - sysTime#ms Load class summary...</p>
		<!---<cfdump var="#QItemSummary#" label="QItemSummary" expand="false">--->
		
		<cfset sysTime = GetTickCount()>
		<cfquery name="QCashback" datasource="#parm.datasource#">
			SELECT SUM(ehCashback) AS total
			FROM tblEPOS_Header
			WHERE ehTimeStamp > '#form.reportDateFrom#'
			AND ehTimeStamp < '#endofDay#'
		</cfquery>
		<cfset tickNow = GetTickCount()>
		<p>#tickNow - sysTime#ms Load cashback summary...</p>
		
		<cfset sysTime = GetTickCount()>
		<cfquery name="QDayHeader" datasource="#parm.datasource#">
			SELECT *
			FROM tblepos_dayheader
			WHERE dhTimeStamp > '#form.reportDateFrom#'
			AND dhTimeStamp < '#endofDay#'
		</cfquery>
		<cfset today = ep.QueryToStruct(QDayHeader)>
		<cfset tickNow = GetTickCount()>
		<p>#tickNow - sysTime#ms Load Day Header...</p>
		
	</cfoutput>
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
	<div id="xreading3" class="totalPanel">
		<div class="header">Shop Daysheet Summary &nbsp; &nbsp; #LSDateFormat(form.reportDateFrom,'ddd dd-mmm-yyyy')# &nbsp; &nbsp; #LSTimeFormat(Now())#</div>
		<table class="tableList" border="1">
			<tr>
				<th>Group</th>
				<th>NCode</th>
				<th>Category</th>
				<th>Class</th>
				<th>Type</th>
				<th>Title</th>
				<th align="right">DR</th>
				<th align="right">CR</th>
				<th align="right">Count</th>
			</tr>
			<!---<cfset tillTotals = {}>--->
			<cfset crtotal = 0>
			<cfset drtotal = 0>
			<cfset vatTotal = 0>
			<cfset countTotal = 0>
			<cfset productTotals = {}>
			<cfloop query="QItemSummary">
				<cfset countTotal += itemCount>
				<cfset vatTotal += vat>
				<cfset gross = net + vat>
				<cfif gross gt 0>
					<cfset drtotal += gross>
				<cfelse>
					<cfset crtotal += gross>
				</cfif>
<!---				<cfif StructKeyExists(tillTotals,eiType)>
					<cfset typeTotal = StructFind(tillTotals,eiType)>
					<cfset typeTotal += gross>
					<cfset StructUpdate(tillTotals,eiType,typeTotal)>
				<cfelse>
					<cfset StructInsert(tillTotals,eiType,gross)>
				</cfif>
--->
				<cfif StructKeyExists(productTotals,prodID)>
					<cfset prod = StructFind(productTotals,prodID)>
					<cfset prod.qty += Qty>
					<cfset prod.value += (net + VAT)>
					<cfset StructUpdate(productTotals,prodID,prod)>
				<cfelse>
					<cfset StructInsert(productTotals,prodID,{"Title"=prodTitle,"Qty"=Qty, "Value"=(net + VAT)})>
				</cfif>
				<tr>
					<td>#pcatGroup#</td>
					<td>#pgNomGroup#</td>
					<td>#prodEposCatID#</td>
					<td>#eiClass#</td>
					<td>#eiType#</td>
					<td>#pgTitle#</td>
					<td align="right"><cfif gross gt 0>#DecimalFormat(net)#</cfif></td>
					<td align="right"><cfif gross lt 0>#DecimalFormat(-net)#</cfif></td>
					<td align="right">#itemCount#</td>
				</tr>
			</cfloop>
			<tr>
				<td></td>
				<td></td>
				<td></td>
				<td>SALES VAT TOTAL</td>
				<td></td>
				<td></td>
				<td align="right"><cfif vatTotal gt 0>#DecimalFormat(vatTotal)#</cfif></td>
				<td align="right"><cfif vatTotal lt 0>#DecimalFormat(-vatTotal)#</cfif></td>
				<td></td>
			</tr>
			<tr>
				<th align="right" colspan="6">Totals</th>
				<th align="right">#DecimalFormat(drtotal)#</th>
				<th align="right">#DecimalFormat(-crtotal)#</th>
				<th align="right">#countTotal#</th>
			</tr>
			<!---<cfdump var="#tillTotals#" label="tillTotals" expand="false">--->
			<cfif abs(drtotal + crtotal) gt 0.001>
				<tr>
					<th align="right" colspan="5">Difference</th>
					<th></th>
					<th align="right">#DecimalFormat(drtotal + crtotal)#</th>
					<th></th>
					<th></th>
				</tr>
			</cfif>
		</table>
		<!---<cfdump var="#productTotals#" label="productTotals" expand="false">--->
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
				<th><strong>Totals</strong></th>
				<th align="right"><strong>#DecimalFormat(drTotal)#</strong></th>
				<th align="right"><strong>#DecimalFormat(crTotal)#</strong></th>
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
				<cfif abs(drtotal - crtotal) gt 0.01>
				<tr>
					<th align="right" colspan="3">Difference</th>
					<th align="right">#DecimalFormat(drtotal - crtotal)#</th>
				</tr>
				</cfif>
			</table>
		</div>
		<div id="xreading7" class="totalPanel">
			<div class="header">Account Totals</div>
			<cfset checkTotal = 0>
			<cfset cashTaken = GetTotal(epos.accounts,"cashindw") + GetTotal(epos.accounts,"supplier") + GetTotal(epos.accounts,"float") + val(QCashback.total)>
			<table class="tableList" border="1">
				<tr>
					<th>Description</th>
					<th width="70" align="right">Value</th>
				</tr>
				<cfloop collection="#epos.accounts#" item="key">
					<cfset value = StructFind(epos.accounts,key)>
					<cfif value neq 0>
						<cfif ListFind("SUPPLIER|CARDINDW",key,"|")>
						<cfelse>
							<cfset checkTotal += value>
							<tr>
								<td>#key#</td>
								<td align="right">#value#</td>
							</tr>
						</cfif>
					</cfif>
				</cfloop>
				<tr>
					<td>&nbsp;Check Total</td>
					<td align="right">#checkTotal#</td>
				</tr>
				<tr>
					<td>Card Payments:</td>
					<td align="right">#DecimalFormat(epos.accounts.cardindw - val(QCashback.total))#</td>
				</tr>
				<tr>
					<td>Supplier COD Payments:</td>
					<td align="right">#GetTotal(epos.accounts,"supplier")#</td>
				</tr>
				<tr>
					<td>Cashback:</td>
					<td align="right">#DecimalFormat(val(QCashback.total))#</td>
				</tr>
				<tr>
					<th>Cash in Drawer:</th>
					<th align="right">#GetTotal(epos.accounts,"cashindw")#</th>
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
					<th>Coin Total</th>
					<th align="right">#DecimalFormat(coinTotal)#</th>
				</tr>
				<tr>
					<th>Note Total</th>
					<th align="right">#DecimalFormat(noteTotal)#</th>
				</tr>
				<tr>
					<th>Cash Total</th>
					<th align="right">#DecimalFormat(noteTotal + coinTotal)#</th>
				</tr>
				<tr>
					<th>Difference</th>
					<th align="right">#DecimalFormat(noteTotal + coinTotal - GetTotal(epos.accounts,"cashindw"))#</th>
				</tr>
			</table>
		</div>
		<div id="xreading8" class="totalPanel">
			<div class="header">Scratch Cards</div>
				<table class="tableList" border="1">
					<tr>
						<th>Game</th>
						<th>Pack</th>
						<th>Value</th>
						<th>Start</th>
						<th>End</th>
						<th>Qty</th>
						<th>Total</th>
					</tr>
					<cfset totalSC = 0>
					<cfset gameValues = [5,5,3,3,2,2,1,1]>
					<cfset packQtys = [60,60,60,60,120,120,180,180]>
					<cfloop from="1" to="8" index="game">
						<cfset gStart = "dhsc_g#game#_start">
						<cfset gEnd = "dhsc_g#game#_end">
						<cfset addPack = 0>
						<cfset sold = 0>
						<cfset value = 0>
						<cfset start = StructFind(today,gStart)>
						<cfset end = StructFind(today,gEnd)>
						<cfif end lt start><cfset addPack = packQtys[game]></cfif>
						<cfset sold = val(end) + addPack - val(start)>
						<cfset value = sold * gameValues[game]>
						<cfset totalSC += value>
						<cfif end eq 0><cfset end = ""></cfif>
						<cfif sold eq 0><cfset sold = ""></cfif>
						<cfif value eq 0><cfset value = "">
							<cfelse><cfset value = DecimalFormat(value)></cfif>
						<tr>
							<td>#game# ##</td>
							<td>#packQtys[game]#</td>
							<td>&pound;#gameValues[game]#</td>
							<td align="right">#start#</td>
							<td align="right">#end#</td>
							<td align="right">#sold#</td>
							<td align="right">#value#</td>
						</tr>
					</cfloop>
					<tr>
						<th colspan="6" align="right">Total</th>
						<th align="right">#DecimalFormat(totalSC)#</th>
					</tr>
				</table>
			</div>
		</div>
	</cfif>

	<div style="clear:both"></div>
	<div class="totalPanel">
		<div class="header">Tran Dump</div>
		<cfset parm = {}>
		<cfset parm.reportDateFrom = form.reportDateFrom>
		<cfset parm.reportDateTo = LSDateFormat(DateAdd("d",1,form.reportDateFrom),"yyyy-mm-dd")>
		<cfset parm.fixTotals = StructKeyExists(form,"fixTotals")>
		<cfset tillTotals = ecfc.DumpTrans(parm)>
		<!---<cfdump var="#tillTotals#" label="tillTotals" expand="false">--->
	</div>
	<div style="clear:both"></div>
</cfif>
</cfoutput>
</body>
</html>