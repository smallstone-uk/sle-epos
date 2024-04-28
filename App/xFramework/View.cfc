component
{
    /**
     * Constructor method for view.
     *
     * @return any
     */
    public any function init(string name = "", struct args = {}, boolean returnEarly = false)
    {
        if (!directoryExists(getBaseDir('Views/temp'))) {
            directoryCreate(getBaseDir('Views/temp'));
        }

        if (name == "") {
            return this;
        }

        this.args = args;
        this.name = name;
        this.layout = '';

        if (findNoCase('|', name) != 0) {
            this.layout = listFirst(name, '|');
            this.name = listLast(name, '|');
        }

        this.file = getFile(this.name);
        this.tempName = uniqueName();
        this.filePath = this.writeViewFile();

        if (returnEarly) {
            return this;
        }

        request.viewContent = this.getContents();

        if (this.layout != '') {
            var layoutView = view(this.layout, this.args, true);

            saveContent variable = "layoutContent" {
                include layoutView.getRelativePath();
            }

            writeOutput(layoutContent);
            fileDelete(layoutView.filePath);
        } else {
            writeOutput(request.viewContent);
        }

        fileDelete(this.filePath);

        return this;
    }

    /**
     * Gets a unique name for the file.
     *
     * @return string
     */
    public string function uniqueName()
    {
        return lCase(createUUID());
    }

    /**
     * Writes the view content to a new temp file.
     * Returns an absolute file path.
     *
     * @return string
     */
    public string function writeViewFile()
    {
        var content = fileRead(this.file);
        var tempFile = getBaseDir("Views\temp\#this.tempName#.cfm");

        fileWrite(tempFile, content);

        return tempFile;
    }

    /**
     * Gets the relative path of the view temp file.
     *
     * @return string
     */
    public string function getRelativePath()
    {
        return "..\..\Views\temp\#this.tempName#.cfm";
    }

    /**
     * Gets the content of the view with its arguments.
     *
     * @return string
     */
    public string function getContents()
    {
        saveContent variable = "viewContent" {
            for (arg in this.args) {
                setVariable(arg, this.args[arg]);
            }

            include "..\..\Views\temp\#this.tempName#.cfm";
        }

        return viewContent;
    }

    /**
     * Gets the paths for the given view name.
     *
     * @return array
     */
    public array function getPaths(required string name)
    {
        this.paths = [];

        if (findNoCase(".", name) > 0) {
            this.paths = listToArray(name, ".");
        } else if (findNoCase("/", name) > 0) {
            this.paths = listToArray(name, "/");
        } else if (findNoCase("\", name) > 0) {
            this.paths = listToArray(name, "\");
        } else {
            this.paths = [name];
        }

        return this.paths;
    }

    /**
     * Gets the absolute file path of the given view.
     *
     * @return string
     */
    public string function getFile(required string name)
    {
        return getBaseDir("Views\#arrayToList(this.getPaths(name), '\')#.cfm");
    }

    /**
     * Gets the relative file path of the given view.
     *
     * @return string
     */
    public string function getFileRel(required string name)
    {
        return "..\..\Views\#arrayToList(this.getPaths(name), '\')#.cfm";
    }
}
