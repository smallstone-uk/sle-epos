<cftry>
<cfobject component="code/epos" name="epos">
<cfset parm = {}>
<cfset parm.datasource = application.site.datasource1>
<cfset parm.url = application.site.normal>
<cfset currentDate = Now()>
<cfset cYear = cyear>
<cfset cMonth = cmonth>
<cfset pDate = "#cYear##cMonth#1">

<cfoutput>
	<script>
		$(document).ready(function(e) {
			var year = Number("#cYear#"),
				month = Number("#cMonth#"),
				now = "#DateFormat(currentDate, 'd')#",
				nowDate = "#DateFormat(currentDate, 'yyyy/m/d')#";
				
			findCurrentDay = function() {
				var nowDateObj = new Date(nowDate);
				var curDateObj = new Date();
				
				$('.CalDayItem[data-date="' + nowDate + '"]').css("background", "#session.user.prefs.empAccent#");
				$('.CalDayItem[data-date="' + nowDate + '"]').find('.CDIDayIndex').css("color", "##FFF");
				
				if (nowDateObj.getFullYear() <= curDateObj.getFullYear() && nowDateObj.getMonth() <= curDateObj.getMonth() && nowDateObj.getDate() <= curDateObj.getDate()) {
					for (var i = 0; i < now; i++) {
						$('.CalDayItem[data-index="' + i + '"]')
							.addClass("CalDayItem_Disabled")
							.attr("data-past", "true")
							.removeClass("CalDayItem");
					}
				}
			}
			
			findCurrentDay();
			
			changeCalendar = function(a, b) {
				$.ajax({
					type: "POST",
					url: "ajax/loadCalendar.cfm",
					data: {
						"cyear": b,
						"cmonth": a
					},
					success: function(data) {
						$('.popup_box').html(data);
						$('.popup_box').center();
					}
				});
			}
			
			$('.CalYearLeft').click(function(event) {
				changeCalendar(month, (year -= 1));
			});
			
			$('.CalYearRight').click(function(event) {
				changeCalendar(month, (year += 1));
			});
			
			$('.CalMonthLeft').click(function(event) {
				if (month != 1) {
					newMonth = month - 1;
				} else {
					newMonth = 12;
				}
				changeCalendar(newMonth, year);
			});
			
			$('.CalMonthRight').click(function(event) {
				if (month != 12) {
					newMonth = month + 1;
				} else {
					newMonth = 1;
				}
				changeCalendar(newMonth, year);
			});
		});
	</script>
	<div class="FCCalendar">
		<div class="CalHeaderLeft">
			<div class="CalYearLeft"></div>
			<div class="CalYearHeader">#cYear#</div>
			<div class="CalYearRight"></div>
		</div>
		<div class="CalHeaderRight">
			<div class="CalMonthLeft"></div>
			<div class="CalMonthHeader" data-month="#cMonth#">#epos.MonthName(cMonth)#</div>
			<div class="CalMonthRight"></div>
		</div>
		<table id="CalWeekDaysTable">
			<tr id="CalWeekDayRow">
				<cfloop from="1" to="7" index="i">
					<th data-weekDay="#i#" class="CalWeekDayCell">#Left(DayOfWeekAsString(i), 3)#</th>
				</cfloop>
			</tr>
		</table>
		<table id="CalDayItemsTable">
			<cfset firstOfTheMonth = CreateDate(cYear, cMonth, 1)>
			<cfset paramDate = "#cYear#-#cMonth#-01">
			<cfset dow = DayOfWeek(firstOfTheMonth)>
			<cfset pad = dow - 1>
			<tr class="CalWeekRowItem">
				<cfif pad gt 0>
					<cfloop from="1" to="#pad#" index="p">
						<td class="CalDayItem_Inactive"></td>
					</cfloop>
				</cfif>
				<cfset days = DaysInMonth(paramDate)>
				<cfset counter = pad + 1>
				<cfloop from="1" to="#days#" index="i">
					<cfset parm.currentLoopDate = "#cyear#-#cmonth#-#i#">
					<td
						id="CDI_#i#"
						class="CalDayItem"
						data-date="#cYear#/#cMonth#/#i#"
						data-day="#DateFormat('#cYear#/#cMonth#/#i#', 'ddd')#"
						data-index="#i#"
						data-past="false"
					>
						<span class="CDIDayIndex">#i#</span>
					</td>
					<cfset counter = counter + 1>
					<cfif counter is 8>
						</tr>
						<cfif i lt days>
							<cfset counter = 1>
							<tr>
						</cfif>
					</cfif>
				</cfloop>
				<cfif counter is NOT 8>
					<cfset endPad = 8 - counter>
					<cfloop from="1" to="#endPad#" index="ep">
						<td class="CalDayItem_Inactive"></td>
					</cfloop>
				</cfif>
			</tr>
		</table>
	</div>
</cfoutput>

<cfcatch type="any">
	<cfdump var="#cfcatch#" label="cfcatch" expand="yes" format="html" 
			output="#application.site.dir_logs#epos\err-#DateFormat(Now(),'yyyymmdd')#-#TimeFormat(Now(),'HHMMSS')#.htm">
</cfcatch>
</cftry>