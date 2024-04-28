<cfheader name="Access-Control-Allow-Origin" value="http://lweb.shortlanesendstore.co.uk" />

<cfscript>
	function getPrimes(num) {
		var i = 1;
		var p = 1;
		var m = 0;
		var t = 0;
		var l = 0;
		var arr = [];
		var arr2 = [];
		
		while (++i <= num) arr[i - 1] = i;
		
		while(p < arrayLen(arr)) {
			i = 0;
			arr2 = arr;
			
			while (++i <= arrayLen(arr2)) {
				m = arr[p] * arr2[i];
				t = arr.indexOf(m);
				if(t > -1) arrayDeleteAt(arr, t + 1); 
				if(m >= num) break;
			}
			
			p++;
		}		
		
		return arr;
	}
</cfscript>

<cfdump var="#getPrimes(1000000)#" label="getPrimes()" expand="no">