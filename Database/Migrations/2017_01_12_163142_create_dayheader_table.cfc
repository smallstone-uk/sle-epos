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

        table.increments('id');
        table.timestamps();

        for (cid in [
            '5000', '2000', '1000', '500',
            '200', '100', '50', '20',
            '10', '5', '2', '1'
        ]) {
            table.decimal('cid_#cid#', 10, 2).default(0.00);
        }

        for (var i = 1; i <= 8; i++) {
            table.integer('sc_g#i#_start').default(0);
            table.integer('sc_g#i#_end').default(0);
            table.decimal('sc_g#i#_total', 10, 2).default(0.00);
        }

        table.create();
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public void function down()
    {
        schema('tblEPOS_DayHeader').drop();
    }
}
