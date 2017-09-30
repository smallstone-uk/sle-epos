<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Test 1</title>
</head>

<body>
	<cfobject component="#application.site.codePath#" name="e">
	<cfset parm = {}>
	<cfset parm.form.itemClass = 'SHOP'>
	<cfset parm.form.prodSign = 1>
	<cfset parm.form.prodID = 26942>
	<cfset parm.form.prodTitle = "chickeen pasty">
	<cfset parm.form.prodClass = 'multiple'>
	<cfset parm.form.account = 0>
	<cfset parm.form.qty = 1>
	<cfset parm.form.cash = 0>
	<cfset parm.form.credit = 2.95>
	<cfset parm.form.vrate = 20>
	<cfset parm.form.cashonly = 0>
	
	<cfset result = e.AddItem(parm)>
	<cfdump var="#result#" label="AddItem" expand="true">
	<cfdump var="#session#" label="session" expand="false">
</body>
</html>