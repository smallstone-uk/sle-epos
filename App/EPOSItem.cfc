component extends = "Framework.Model"
{
    variables.table = "tblEPOS_Items";
    variables.model = "EPOSItem";

    /**
     * Gets this item's header record.
     *
     * @return any
     */
    public any function header()
    {
        return this.belongsToOne('EPOSHeader', 'eiParent');
    }

    /**
     * Gets this item's product record.
     *
     * @return any
     */
    public any function product()
    {
        return this.hasOne('Product', 'eiProdID');
    }

    /**
     * Gets this item's publication record.
     *
     * @return any
     */
    public any function publication()
    {
        return this.hasOne('Publication', 'eiPubID');
    }

    /**
     * Gets this item's payment record.
     *
     * @return any
     */
    public any function payment()
    {
        return this.hasOne('EPOSAccount', 'eiPayID');
    }

    /**
     * Gets this item's account record.
     *
     * @return any
     */
    public any function account()
    {
        return this.hasOne('EPOSAccount', 'eiAccID');
    }

    /**
     * Gets this item's title.
     *
     * @return any
     */
    public string function title()
    {
        if (this.eiProdID != 1) {
            return this.product().prodTitle;
        }

        if (this.eiPubID != 1) {
            return this.publication().pubTitle;
        }

        if (this.eiPayID != 1) {
            return this.payment().eaTitle;
        }

        if (this.eiAccID != 1) {
            return this.account().eaTitle;
        }

        return '';
    }
}
