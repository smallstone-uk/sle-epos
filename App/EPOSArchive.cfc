component extends = "Framework.Model"
{
    variables.table = "tblEPOS_Archive";
    variables.model = "EPOSArchive";

    public any function decode()
    {
        return deserializeJSON(this.json);
    }

    public string function barcode()
    {
        var padding = left("4500000000000", 13 - len(this.id));
        return left("#padding##this.id#", 13);
    }
}
