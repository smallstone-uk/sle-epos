<cftry>

<cfscript>
	key = form.key;
	parent = session;
	data = -1;

	if (find('.', key) != 0) {
		keys = listToArray(key, '.');
		last = keys[arrayLen(keys)];
		arrayDeleteAt(keys, arrayLen(keys));

		for (k in keys) {
			if (structKeyExists(parent, k)) {
				if (isValid('struct', parent[k])) {
					parent = parent[k];
					continue;
				} else {
					throw("Key '#k#' is not a struct.");
				}
			} else {
				throw("Key '#k#' does not exist in 'session'.");
				break;
			}
		}
		
	//	writeDumpToFile([parent, last, key]);

		data = structFindDefault(parent, last, -1);
	} else {
		data = structFindDefault(parent, key, -1);
	}
</cfscript>

<cfoutput>
    #serializeJSON({ "data" = data })#
</cfoutput>

<cfcatch type="any">
	<cfset writeDumpToFile(cfcatch)>
</cfcatch>
</cftry>
