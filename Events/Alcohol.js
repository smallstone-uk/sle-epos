class Alcohol
{
    /**
     * Called when product is added to basket.
     *
     * @return void
     */
    onAdded(product)
    {
        var date = new Date();
        var isSunday = date.getDay() == 6;

        // if (true) {
        if (isSunday && date.getHours() < 10) {
            $.confirmation("Cannot sell alcohol before 10am on Sunday", function() {}, true);
            return;
        }

        $.confirmation("Ask customer for proof of age");
    }

    /**
     * Called when product is removed from basket.
     *
     * @return void
     */
    onRemoved()
    {
        // TODO Add raiseEvent clause
    }

    /**
     * Called when product in basket is updated.
     *
     * @return void
     */
    onUpdated()
    {
        // TODO Add raiseEvent clause
    }

    /**
     * Called when product in basket is discounted.
     *
     * @return void
     */
    onDiscounted()
    {
        // TODO Add raiseEvent clause
    }

    /**
     * Called when product in basket is bought (transaction closed).
     *
     * @return void
     */
    onBought()
    {
        // TODO Add raiseEvent clause
    }

    /**
     * Called when product is refunded.
     *
     * @return void
     */
    onRefunded()
    {
        // TODO Add raiseEvent clause
    }
}
