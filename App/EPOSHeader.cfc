component extends = "Framework.Model"
{
    variables.table = "tblEPOS_Header";
    variables.model = "EPOSHeader";

    public array function getItems()
    {
        return this.hasMany('EPOSItem', 'ehID', 'eiParent');
    }
}
