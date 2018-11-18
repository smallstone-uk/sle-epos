component extends = "Framework.Model"
{
    variables.table = "tblEPOS_DayHeader";
    variables.model = "DayHeader";

    this.todayStart = '#lsDateFormat(now(), "yyyy-mm-dd")# 00:00:00';
    this.todayEnd = '#lsDateFormat(now(), "yyyy-mm-dd")# 23:59:59';

    /**
     * Checks whether the model can be created.
     * Return true for the creation to continue.
     *
     * @return boolean
     */
    public boolean function canCreate()
    {
        // Allow creation if there is
        // no record for today
        return structIsEmpty(this.today());
    }

    public numeric function zCash()
    {
        return val(this.sql("
            SELECT SUM(eiNet) AS zCash
            FROM tblEPOS_Items
            WHERE eiType = 'CASHINDW'
            AND eiTimestamp >= '#this.todayStart#'
            AND eiTimestamp <= '#this.todayEnd#'
        ").zCash);
    }

    public numeric function lottoDraws()
    {
        return val(this.sql("
            SELECT SUM(eiNet) AS lottoDraws
            FROM tblEPOS_Items
            WHERE eiType = 'LOTTERY'
            AND eiNomID = 2
            AND eiTimestamp >= '#this.todayStart#'
            AND eiTimestamp <= '#this.todayEnd#'
        ").lottoDraws);
    }

    public numeric function scratchCards()
    {
        return val(this.sql("
            SELECT SUM(eiNet) AS scratchCards
            FROM tblEPOS_Items
            WHERE eiType = 'SCRATCHCARD'
            AND eiNomID = 2
            AND eiTimestamp >= '#this.todayStart#'
            AND eiTimestamp <= '#this.todayEnd#'
        ").scratchCards);
    }

    public numeric function lottoPrizes()
    {
        return val(this.sql("
            SELECT SUM(eiNet) AS prizesTotal
            FROM tblEPOS_Items
            WHERE eiType = 'LPRIZE'
            AND eiNomID = 2
            AND eiTimestamp >= '#this.todayStart#'
            AND eiTimestamp <= '#this.todayEnd#'
        ").prizesTotal);
    }

    public numeric function scratchPrizes()
    {
        return val(this.sql("
            SELECT SUM(eiNet) AS prizesTotal
            FROM tblEPOS_Items
            WHERE eiType = 'SPRIZE'
            AND eiNomID = 2
            AND eiTimestamp >= '#this.todayStart#'
            AND eiTimestamp <= '#this.todayEnd#'
        ").prizesTotal);
    }

    /**
     * Gets today's day header record.
     *
     * @return Model
     */
    public any function today()
    {
		var from = createDateTime(year(now()), month(now()), day(now()), 0, 0, 0);
		var to = createDateTime(year(now()), month(now()), day(now()), 23, 59, 59);

        var records = this.timeframe('dhTimestamp', from, to);

        return (arrayIsEmpty(records)) ? {} : records[1];
    }
	
    /**
     * Gets yesterday's day header record for the scratch card numbers.
     *
     * @return Model
     */
    public any function yesterday()
    {
		var from = createDateTime(year(now()), month(now()), day(now()), 0, 0, 0);
		var to = createDateTime(year(now()), month(now()), day(now()), 23, 59, 59);
		from = DateAdd("d",-1,from);
		to = DateAdd("d",-1,to);
        var records = this.timeframe('dhTimestamp', from, to);

        return (arrayIsEmpty(records)) ? {} : records[1];
    }
}
