<cfscript>
    try {
        // If no value was passed, default it to 0.00
        for (field in form) {
            if (isValid("string", form[field]) && form[field] == '') {
                form[field] = 0.00;
            }
        }

        dayHeader = {};
        today = new App.DayHeader().today();

        if (structIsEmpty(today)) {
            // Create a new record for today
            dayHeader = new App.DayHeader().save(form);
        } else {
            // Update the existing record for today
            dayHeader = new App.DayHeader(today.dhID).save(form);
        }
    } catch(any error) {
        writeDumpToFile(error);
    }
</cfscript>

<cfoutput>
    <!--- Summary View --->
    <cfset writeDump(dayHeader)>
</cfoutput>
