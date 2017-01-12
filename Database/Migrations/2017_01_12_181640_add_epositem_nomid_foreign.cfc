component
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public void function up()
    {
        var table = schema('tblEPOS_Items');
        table.foreign('eiNomID').references('tblEPOS_Account', 'eaID').onDelete('restrict');
        table.update();
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public void function down()
    {
        schema('tblEPOS_Items').dropForeign('eiNomID');
    }
}
