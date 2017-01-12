<cfscript>
    try {
        for (field in form) {
            if (isValid("string", form[field]) && form[field] == '') {
                form[field] = 0.00;
            }
        }

        dayHeader = new App.DayHeader().save(form);
        writeDumpToFile(dayHeader);
    } catch(any error) {
        writeDumpToFile(error);
    }
</cfscript>
