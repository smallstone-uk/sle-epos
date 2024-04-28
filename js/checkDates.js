<!--- Version 1.00	25/06/07 Date field validation --->

	function numberInRange(object_value, min_value, max_value)	{
		if (min_value !== null)	{
			if (object_value < min_value)
				{return false;}
		}
		if (max_value !== null)	{
			if (object_value > max_value)
				{return false;}
		}
		return true;
	}
	function checkrange(object_value, min_value, max_value)	{
		if (object_value.length === 0)
			{return true;}
		return (numberInRange((eval(object_value)), min_value, max_value));
	}
	
	function checkDateFormat(object_value)	{
		if (object_value.length === 0)		// blank field is OK
			{return true;}
		var isplit = object_value.indexOf('/');		// check if slash delimiter used
		if (isplit === -1)
			{isplit = object_value.indexOf('-');}		// check if dash delimiter used
		if (isplit === -1 || isplit === object_value.length)		// no delimiters found
				{return false;}
		var sDay = object_value.substring(0, isplit);	// get day element
		var monthSplit = isplit + 1;
		isplit = object_value.indexOf('/', monthSplit);	
		if (isplit === -1)
			{isplit = object_value.indexOf('-', monthSplit);}
		if (isplit === -1 ||  (isplit + 1 )  === object_value.length)  // can't find month
				{return false;}
		var sMonth = object_value.substring((sDay.length + 1), isplit);	
		if (!checkrange(sMonth, 1, 12)) {return false;}	// month out of range
		var sYear = object_value.substring(isplit + 1);
		return checkMaxDay(+sYear,+sMonth,+sDay);
	}
	
	// new version 01/03/2014
	function checkMaxDay(checkYear, checkMonth, checkDay)	{
		var maxDay = 31;
		if (checkDay < 1 || checkMonth < 1 || checkMonth > 12) return false;
		if (checkMonth === 4 || checkMonth === 6 || checkMonth === 9 || checkMonth === 11)
			{maxDay = 30;}
		else if (checkMonth === 2)	{
			if (checkYear % 4 > 0) {maxDay =28;}
			else if (checkYear % 100 === 0 && checkYear % 400 > 0)
				{maxDay = 28; } else {maxDay = 29;}
		}
		return checkDay <= maxDay;
	}
	function checkDate(dateStr,futureOK) {
		var now=new Date();
		now.setHours(0, 0, 0, 0);
		var thisDay=now.getDate();
		var thisMonth=now.getMonth()+1;
		var thisYear=now.getFullYear();
		var re=/[\/\.\s]/;
		var fields = dateStr.split(re);
		var dayNum=parseInt(+fields[0]);
		var dateStr="";
		dayNum = dayNum ? dayNum : thisDay;
		var mnthNum=parseInt(+fields[1]);
		mnthNum = mnthNum ? mnthNum : thisMonth;
		var yrNum=parseInt(+fields[2]);
		yrNum = yrNum ? yrNum : thisYear;
		yrNum = yrNum<100 ? 2000+yrNum : yrNum;
		if (checkMaxDay(yrNum,mnthNum,dayNum)) {
			dayNum = dayNum > 9 ? dayNum : "0" + dayNum;
			mnthNum = mnthNum > 9 ? mnthNum : "0" + mnthNum;
			dateStr=dayNum+'/'+mnthNum+'/'+yrNum
			var cleanDate=new Date(yrNum,mnthNum-1,dayNum)
			if (futureOK || (cleanDate <= now))
				return dateStr
			else return false
		} else return false
	}
	