component extends = "Framework.Model"
{
    variables.table = "tblEPOS_DayHeader";
    variables.model = "DayHeader";

    this.todayStart = '#lsDateFormat(now(), "yyyy-mm-dd")# 00:00:00';
    this.todayEnd = '#lsDateFormat(now(), "yyyy-mm-dd")# 23:59:59';

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
}
