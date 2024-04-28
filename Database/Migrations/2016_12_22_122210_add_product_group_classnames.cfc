component
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public void function up()
    {
        var table = schema('tblProductGroups');

        table.string('pgClassname').nullable().default('Common');

        table.update();
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public void function down()
    {
        schema('tblProductGroups').dropColumn('pgClassname');
    }
}
