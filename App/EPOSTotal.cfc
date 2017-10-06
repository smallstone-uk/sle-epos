component extends = "Framework.Model"
{
    variables.table = "tblEPOS_Totals";
    variables.model = "EPOSTotal";

    /**
     * Gets the list of account totals for the given date.
     *
     * @return struct
     */
    public struct function getTotals(required any date)
    {
        var data = { 'accounts' = {} };
        var totals = this.where('totDate', date).get();

        for (total in totals) {
            structInsert(data.accounts, total.totAcc, total.totValue, true);
        }

        return data;
    }
}
