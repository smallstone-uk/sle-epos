component
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public void function up()
    {
        var table = schema('tblEPOS_Archive');
        table.increments('id');
        table.timestamps();
        table.longText('json');
        table.create();
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public void function down()
    {
        schema('tblEPOS_Archive').drop();
    }
}
