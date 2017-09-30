component
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public void function up()
    {
        var table = schema('tblEPOS_DayHeader');
		
		table.dropcolumn('dhSC_G9_Start');
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public void function down()
    {
        
    }
}
