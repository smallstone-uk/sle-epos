<!--- Legacy functions that are not supported in cfscript in CF9 --->
<!--- Do not delete --->
<cfcomponent>
    <cffunction name="constructModelObject" access="public" returntype="struct">
        <cfargument name="table" type="string" required="true">
        <cfargument name="datasource" type="string" required="true">

        <cfset var loc = {}>
        <cfset loc.result = {
            "data" = {},
            "columns" = [],
            "columnTypes" = {},
            "nullColumns" = [],
            "primaryKeyField" = ""
        }>

        <cfquery name="loc.schema" datasource="#datasource#">
            DESCRIBE #arguments.table#
        </cfquery>

        <cfloop query="loc.schema">
            <cfset loc.type = parseType(type)>
            <cfset loc.rowIsNull = loc.schema.getString("default")>

            <cfif arrayContains(["int","int unsigned"], loc.type) AND default eq "">
                <cfset default = 0>
            </cfif>

            <cfif NOT structKeyExists(loc, "rowIsNull")>
                <cfset arrayAppend(loc.result.nullColumns, field)>
            </cfif>

            <cfset structInsert(loc.result.data, field, default)>
            <cfset arrayAppend(loc.result.columns, field)>
            <cfset structInsert(loc.result.columnTypes, field, loc.type)>

            <cfif key eq "PRI">
                <cfset loc.result.primaryKeyField = field>
                <cfset loc.result.data[field] = -1>
            </cfif>
        </cfloop>

        <cfreturn loc.result>
    </cffunction>

    <cffunction name="parseType" access="private" returntype="string">
        <cfargument name="value" required="true" type="string">
        <cfreturn reReplace(arguments.value, "\([\d\D]*\)", "", "all")>
    </cffunction>

    <cffunction name="cookie" access="public" returntype="void">
        <cfargument name="c_name" required="true" type="string">
        <cfargument name="c_value" required="true" type="string">
        <cfargument name="c_expires" required="true" type="string">

        <cfif structKeyExists(cookie, c_name)>
            <cfcookie
                name = "#c_name#"
                value = "#c_value#"
                expires = "#c_expires#">
        </cfif>
    </cffunction>

    <cffunction name="fileToLines" access="public" returntype="array">
        <cfargument name="filePath" required="true" type="string">
        <cfset var lines = []>

        <cfloop file="#filePath#" index="line">
            <cfset arrayAppend(lines, line)>
        </cfloop>

        <cfreturn lines>
    </cffunction>

    <cffunction name="createTokenCookie" access="public" returntype="void">
        <cfargument name="token" required="true" type="string">
        <cfcookie name="cfuser" value="#token#" httponly="true" expires="never">
    </cffunction>

    <cffunction name="invokeMethod" access="public" returntype="void">
        <cfargument name="c" required="true" type="string">
        <cfargument name="m" required="true" type="string">
        <cfargument name="a" required="true" type="struct">
        <cfargument name="o" required="false" type="array" default="[]">

        <cfset var oi = 0>

        <cfinvoke
            component="#c#"
            method="#m#">

            <cfloop array="#o#" index="oi">
                <cfinvokeargument
                    name="#oi#"
                    value="#a[oi]#">
                </cfinvokeargument>
            </cfloop>
        </cfinvoke>
    </cffunction>

    <cffunction name="httpRequest" access="public" returntype="any">
        <cfargument name="fullurl" required="true" type="string">
        <cfargument name="method" required="true" type="string">
        <cfargument name="formdata" required="true" type="struct">

        <cfset var httpResponse = "">

        <cfhttp url="#fullurl#" method="#method#" result="httpResponse" timeout="60">
            <cfloop collection="#formdata#" item="key">
                <cfhttpparam type="formfield" name="#key#" value="#structFind(formdata, key)#">
            </cfloop>
        </cfhttp>

        <cfreturn httpResponse>
    </cffunction>

    <cffunction name="xmlToStruct" access="public" returntype="struct" output="true">
        <cfargument name="xmlNode" type="string" required="true" />
        <cfargument name="str" type="struct" required="true" />
        <!---Setup local variables for recurse: --->
        <cfset var i = 0 />
        <cfset var axml = arguments.xmlNode />
        <cfset var astr = arguments.str />
        <cfset var n = "" />
        <cfset var tmpContainer = "" />
    
        <cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
        <cfset axml = axml[1] />
        <!--- For each children of context node: --->
        <cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
            <!--- Read XML node name without namespace: --->
            <cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
            <!--- If key with that name exists within output struct ... --->
            <cfif structKeyExists(astr, n)>
                <!--- ... and is not an array... --->
                <cfif not isArray(astr[n])>
                    <!--- ... get this item into temp variable, ... --->
                    <cfset tmpContainer = astr[n] />
                    <!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
                    <cfset astr[n] = arrayNew(1) />
                    <!--- ... and reassing temp item as a first element of new array: --->
                    <cfset astr[n][1] = tmpContainer />
                <cfelse>
                    <!--- Item is already an array: --->
                    
                </cfif>
                <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
                        <!--- recurse call: get complex item: --->
                        <cfset astr[n][arrayLen(astr[n])+1] = xmlToStruct(axml.XmlChildren[i], structNew()) />
                <cfelse>
                        <!--- else: assign node value as last element of array: --->
                        <cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
                </cfif>
            <cfelse>
                <!---
                    This is not a struct. This may be first tag with some name.
                    This may also be one and only tag with this name.
                --->
                <!---
                        If context child node has child nodes (which means it will be complex type): --->
                <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
                    <!--- recurse call: get complex item: --->
                    <cfset astr[n] = xmlToStruct(axml.XmlChildren[i], structNew()) />
                <cfelse>
                    <cfif IsStruct(aXml.XmlAttributes) AND StructCount(aXml.XmlAttributes)>
                        <cfset at_list = StructKeyList(aXml.XmlAttributes)>
                        <cfloop from="1" to="#listLen(at_list)#" index="atr">
                             <cfif ListgetAt(at_list,atr) CONTAINS "xmlns:">
                                 <!--- remove any namespace attributes--->
                                <cfset Structdelete(axml.XmlAttributes, listgetAt(at_list,atr))>
                             </cfif>
                         </cfloop>
                         <!--- if there are any atributes left, append them to the response--->
                         <cfif StructCount(axml.XmlAttributes) GT 0>
                             <cfset astr['_attributes'] = axml.XmlAttributes />
                        </cfif>
                    </cfif>
                    <!--- else: assign node value as last element of array: --->
                    <!--- if there are any attributes on this element--->
                    <cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
                        <!--- assign the text --->
                        <cfset astr[n] = axml.XmlChildren[i].XmlText />
                            <!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
                         <cfset attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes) />
                         <cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
                             <cfif ListgetAt(attrib_list,attrib) CONTAINS "xmlns:">
                                 <!--- remove any namespace attributes--->
                                <cfset Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
                             </cfif>
                         </cfloop>
                         <!--- if there are any atributes left, append them to the response--->
                         <cfif StructCount(axml.XmlChildren[i].XmlAttributes) GT 0>
                             <cfset astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes />
                        </cfif>
                    <cfelse>
                         <cfset astr[n] = axml.XmlChildren[i].XmlText />
                    </cfif>
                </cfif>
            </cfif>
        </cfloop>
        <!--- return struct: --->
        <cfreturn astr />
    </cffunction>
</cfcomponent>
