
// Day sheet summary
SELECT eiClass, eiType, SUM(eiNet) AS net, SUM(eiVAT) as vat
FROM tblEPOS_Items 
INNER JOIN tblEPOS_Header ON ehID = eiParent 
WHERE DATE(ehTimeStamp) = '2016-07-19' 
GROUP by eiClass, eiType


// Day Sheet summary 2
SELECT pcatGroup, prodCatID, eiClass, eiType, pgTitle, SUM(eiNet) AS net, SUM(eiVAT) as vat
FROM `tblEPOS_Items`
INNER JOIN tblEPOS_Header ON ehID = eiParent
INNER JOIN tblProducts ON prodID = eiProdID
INNER JOIN tblProductCats ON pcatID = prodCatID
INNER JOIN tblProductGroups ON pgID = pcatGroup
WHERE DATE( ehTimeStamp ) = '2016-07-19'
GROUP by eiClass, eiType, pgTitle


// Day sheet details
SELECT ehTimeStamp, prodCatID, pgTitle, pcatTitle, tblEPOS_Items . *
FROM `tblEPOS_Items`
INNER JOIN tblEPOS_Header ON ehID = eiParent
INNER JOIN tblProducts ON prodID = eiProdID
INNER JOIN tblProductCats ON pcatID = prodCatID
INNER JOIN tblProductGroups ON pgID = pcatGroup
WHERE DATE( ehTimeStamp ) = '2016-07-19'


// products assocciated with a deal
SELECT tblEPOS_DealItems. * , prodCatID, prodTitle
FROM `tblEPOS_DealItems`
INNER JOIN tblProducts ON prodID = ediProduct
WHERE 1
ORDER BY ediParent


// Products & categories included in daysheet analysis
SELECT pcatGroup, prodID,prodTitle,prodCatID,prodEposCatID, eiClass, eiType, pgTitle, eiNet,eiVAT
FROM tblEPOS_Items
INNER JOIN tblEPOS_Header ON ehID = eiParent 
INNER JOIN tblProducts ON prodID = eiProdID 
INNER JOIN tblProductCats ON pcatID = prodCatID 
INNER JOIN tblProductGroups ON pgID = pcatGroup 
WHERE DATE( ehTimeStamp ) = '2016-10-17'


// User cats
SELECT tblEPOS_EmpCats . * , epcTitle, epcParent
FROM `tblEPOS_EmpCats`
INNER JOIN tblEPOS_Cats ON eecCategory = epcID
WHERE eecEmployee =122
ORDER BY eecOrder


//Products & stock items price check where product ourprice <> stock item ourprice
SELECT prodID,prodTitle,siUnitSize,prodLastBought,prodPriceMarked,prodOurPrice,
siRRP,siOurPrice,siPOR,siID	
FROM tblProducts
INNER JOIN tblEPOS_Cats ON epcID = prodEposCatID
LEFT JOIN tblStockItem ON prodID = siProduct
AND tblStockItem.siID = (
	SELECT MAX( siID )
	FROM tblStockItem
	WHERE prodID = siProduct )
WHERE prodOurPrice!=siOurPrice


// Clone user EPOS buttons to new user. Change EMPLOYEE_ID to required user.
// Gets the records assigned to User 122 and inserts them for the specified user.
INSERT INTO tblepos_empcats (eecEmployee,eecCategory,eecOrder) 
SELECT EMPLOYEE_ID,eecCategory,eecOrder FROM `tblepos_empcats` WHERE `eecEmployee` = 122


// Insert product records based on source data from labels table.
INSERT INTO tblProducts (prodCatID,prodSuppID,prodTitle)
SELECT 332,labID,labTitle FROM tblLabels WHERE prodCatID IN (6892,19882,19892)



