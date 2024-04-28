component extends = "Framework.Model"
{
    variables.table = "tblProductGroups";
    variables.model = "ProductGroup";

    public any function createGroupProducts()
    {
        var groups = new App.ProductGroup().all();

        for (grp in groups) {
            var product = new App.Product({
                'prodCatID' = 2,
                'prodRecordTitle' = grp.pgTitle,
                'prodTitle' = grp.pgTitle
            }).save();
        }
    }
}
