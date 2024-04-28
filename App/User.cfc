component extends = "Framework.Model"
{
    variables.table = "tblEmployee";
    variables.model = "User";

    public array function getEPOSCategories()
    {
        return this.hasManyToOne(
            'EPOSEmpCat', 'empID', 'eecEmployee',
            'EPOSCat', 'eecCategory', 'epcID',
            'eecOrder', 'asc'
        );
    }
}
