<script type="text/javascript">
	$(document).ready(function(e) {
		var date = new Date();
		var year = date.getFullYear(),
			month = date.getMonth(),
			day = date.getDate();
		var nowDate = year + "/" + (month + 1) + "/" + day;
		monthName = function(index) {
			switch (index)
			{
				case 0: return "January"; break;
				case 1: return "Febuary"; break;
				case 2: return "March"; break;
				case 3: return "April"; break;
				case 4: return "May"; break;
				case 5: return "June"; break;
				case 6: return "July"; break;
				case 7: return "August"; break;
				case 8: return "September"; break;
				case 9: return "October"; break;
				case 10: return "November"; break;
				case 11: return "December"; break;
			}
		}
		daysInMonth = function(y, m) {
			var parsedMonth = m + 1;
			return new Date(y, parsedMonth, 0).getDate();
		}
		loadCalendar = function() {
			$('.FCDPPContent').html("");
			$('.FCDPPDisplay').html(monthName(month) + " " + year);
			var firstOfMonth = new Date(year, month, 1);
			var paramDate = year + "-" + month + "-1";
			var dow = firstOfMonth.getDay();
			var pad = dow;
			var days = daysInMonth(year, month);
			var counter = pad + 1;
			var endPad;
			var padCells = "",
				dayCells = "",
				endPadCells = "";
			if (pad > 0) {
				padCells = "<td colspan='" + pad + "' class='FCDPPWRIDay_Inactive'>&nbsp;</td>";
			}
			for (var i = 1; i <= days; i++) {
				counter++;
				dayCells = dayCells + "<td class='FCDPPWRIDay' data-date='" + year + "/" + (month + 1) + "/" + i + "' onclick='javascript:$(this).selectDay();'>" + i + "</td>";
				if (counter == 8) {
					dayCells = dayCells + "</tr>";
					if (i < days) {
						counter = 1;
						dayCells = dayCells + "<tr>";
					}
				}
			}
			if (counter != 8) {
				endPad = 8 - counter;
				endPadCells = "<td colspan='" + endPad + "' class='FCDPPWRIDay_Inactive'>&nbsp;</td>";
			}
			$('.FCDPPContent').html("<table id='FCDPPCDayItemsTable'><tr class='FCDPPWeekRowItem'>" + padCells + dayCells + endPadCells + "</tr></table>");
			$('.FCDPPWRIDay[data-date="' + nowDate + '"]').addClass("FCDPPWRIDay_Active");
		}
		$('.FCDPPDirMove').click(function(event) {
			var dir = $(this).attr("data-dir");
			switch (dir)
			{
				case "prev":
					if (month == 0) {
						month = 11;
						year--;
					} else {
						month--;
					}
					break;
				case "next":
					if (month == 11) {
						month = 0;
						year++;
					} else {
						month++;
					}
					break;
			}
			loadCalendar();
			event.preventDefault();
		});
		$.fn.selectDay = function() {
			window.setDatePickerValue($(this).attr("data-date"), $('.FCDatePickerPopup').attr("data-dpindex"));
			$('.FCDatePickerPopup').hide();
			var now = new Date();
			year = now.getFullYear();
			month = now.getMonth();
			day = now.getDate();
			loadCalendar();
		}
		loadCalendar();
	});
</script>

<div class="FCDatePickerPopup disable-select" style="display:none;">
	<div class="FCDPPHeader">
		<a href="javascript:void(0)" class="FCDPPDirMove FCDPPDirPrev" data-dir="prev" title="Previous month"></a>
		<span class="FCDPPDisplay"></span>
		<a href="javascript:void(0)" class="FCDPPDirMove FCDPPDirNext" data-dir="next" title="Next month"></a>
	</div>
	<div class="FCDPPWeekDaysContent">
		<table id="FCDPPCWeekDaysTable">
			<tr id="FCDPPCWeekDayRow">
				<th data-weekDay="1" class="FCDPPCWeekDayCell">Sun</th>
				<th data-weekDay="2" class="FCDPPCWeekDayCell">Mon</th>
				<th data-weekDay="3" class="FCDPPCWeekDayCell">Tue</th>
				<th data-weekDay="4" class="FCDPPCWeekDayCell">Wed</th>
				<th data-weekDay="5" class="FCDPPCWeekDayCell">Thu</th>
				<th data-weekDay="6" class="FCDPPCWeekDayCell">Fri</th>
				<th data-weekDay="7" class="FCDPPCWeekDayCell">Sat</th>
			</tr>
		</table>
	</div>
	<div class="FCDPPContent"></div>
</div>