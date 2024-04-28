component extends = "Framework.Model"
{
    variables.table = "tblProducts";
    variables.model = "Product";

    public any function getGroup()
    {
        return this.belongsToOneThrough('ProductGroup', 'ProductCat', 'prodCatID', 'pcatGroup');
    }
}
