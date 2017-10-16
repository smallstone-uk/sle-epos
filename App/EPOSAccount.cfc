component extends = "Framework.Model"
{
    variables.table = "tblEPOS_Account";
    variables.model = "EPOSAccount";

    /**
     * Gets the payable accounts with their balance.
     *
     * @return array
     */
    public array function getPayableAccounts()
    {
        var result = [];
        var accounts = this.where('eaMenu', 'Yes').get();

        for (account in accounts) {
            var id = account.eaID;
            var item = account.flatten();
            item.balance = account.balance();
            item.eaid = id;
            arrayAppend(result, item);
        }

        return result;
    }

    /**
     * Gets the outstanding balance for the account.
     *
     * @return numeric
     */
    public numeric function balance()
    {
        return val(this.sql("
            SELECT eaTitle, SUM(eiNet + eiVAT) AS balance
            FROM tblEPOS_Account
            LEFT JOIN tblEPOS_Items ON eaID = eiAccID
            WHERE eaMenu = 'Yes'
            AND eaID = #this.eaID#
            GROUP BY eaID
        ").balance);
    }
}
