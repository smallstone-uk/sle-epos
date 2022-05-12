class Tobacco
{
    /**
     * Called when product is added to basket.
     *
     * @return void
     */
    onAdded(product)
    {
        $.confirmation("It is illegal to sell tobacco to under 18's.<br>Please ask the customer for proof of age if they appear under 25.",function() {},true);
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
