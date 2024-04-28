component extends = "Framework.Model"
{
    variables.table = "model_table";
    variables.model = "model_name";

    /**
     * Called when a model is about to update.
     * Return true for the update to continue.
     *
     * @return boolean
     */
    public boolean function canUpdate()
    {
        return true;
    }

    /**
     * Called when a model is about to be deleted.
     * Return true for the deletion to continue.
     *
     * @return boolean
     */
    public boolean function canDelete()
    {
        return true;
    }
}
