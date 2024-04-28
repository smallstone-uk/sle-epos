<cfscript>
    try {
        if (!structKeyExists(form, 'mb_method')) {
            abort;
        }

        switch (lCase(form.mb_method)) {
            case 'delete':
                createObject('component', 'App.#form.mb_name#')
                    .init(val(form.mb_id))
                    .delete();
                break;
            case 'save':
                createObject('component', 'App.#form.mb_name#')
                    .init(val(form.mb_id))
                    .save(form);
                break;
            case 'create':
                m = createObject('component', 'App.#form.mb_name#')
                    .init()
                    .save(form);
                writeOutput(serializeJSON(m));
                break;
        }
    } catch (any error) {
        writeDumpToFile(error);
    }
</cfscript>
