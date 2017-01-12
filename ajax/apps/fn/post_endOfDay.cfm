<cfscript>
    try {
        // If no value was passed, default it to 0.00
        for (field in form) {
            if (isValid("string", form[field]) && form[field] == '') {
                form[field] = 0.00;
            }
        }

        dayHeader = new App.DayHeader().save(form);
    } catch(any error) {
        writeDumpToFile(error);
    }
</cfscript>
