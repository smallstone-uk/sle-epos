<cfcomponent
	output="false"
	hint="I am a base Application component meant to be extended by other Application.cfc instances.">


	<!---
		Define the collection of JAR paths to be used for the URL
		class loader in this application.
	--->
	<cfset this.jarPaths = [] />


	<!--- ------------------------------------------------- --->
	<!--- ------------------------------------------------- --->


	<!---
		Append the CreateJava() method to the URL collection. While
		this makes NO sense from a semantic standpoint, the way in
		which variables are "discovered" in ColdFusion allows us to
		use the URL scope to create globally accessible functions.
	--->
	<cfset url.createJava = this.createJava />

	<!---
		Because methods copied by reference do not retain their
		original context, we also have to store a reference to THIS
		Application.cfc instance such that he createJava method can
		get access to the URL classloader instance.
	--->
	<cfset url.createJavaContext = this />


	<!--- ------------------------------------------------- --->
	<!--- ------------------------------------------------- --->


	<cffunction
		name="createJava"
		access="public"
		returntype="any"
		output="false"
		hint="I create the given Java object using the URL class loader powered by the local JAR Paths. NOTE: This will be called OUTSIDE of the context of this Application.cfc; this is why it makes reference to URL-scope values.">

		<!--- Define arguments. --->
		<cfargument
			name="javaClass"
			type="string"
			required="true"
			hint="I am the Java class to be loaded from the class loader."
			/>

		<!--- Define the local scope. --->
		<cfset var local = {} />

		<!---
			Overwrite the THIS context to fake out the rest of this
			function body into thinking it's part of the original
			Application.cfc instance.

			In a UDF, the variable "this" is already declared as a
			LOCAL variable; as such, all we have to do is overwrite
			it for this link to be created.
		--->
		<cfset this = url.createJavaContext />

		<!---
			Check to see if the URL class loader has been created
			for this page request.
		--->
		<cfif !structKeyExists( this, "urlClassLoader" )>

			<!---
				Create the URL class loader. Typically, we'd need to
				create some sort of locking around this; but, this is
				just a proof of concept.
			--->
			<cfset this.urlClassLoader = createObject( "java", "java.net.URLClassLoader" ).init(
				this.toJava(
					"java.net.URL[]",
					this.jarPaths,
					"string"
					),
				javaCast( "null", "" )
				) />

		</cfif>

		<!---
			Create a new instance of the given Java class.

			NOTE: When we use the newInstance() method, it calls the
			default constructor on the class with no arguments. I
			believe that if we want to use constructor arguments, we
			need to get the actual constructor object.
		--->
		<cfreturn this.urlClassLoader
			.loadClass( arguments.javaClass )
				.newInstance()
			/>
	</cffunction>


	<cffunction
		name="toJava"
		access="public"
		returntype="any"
		output="false"
		hint="I convert the given ColdFusion data type to Java using a more robust conversion set than the native javaCast() function.">

		<!--- Define arguments. --->
		<cfargument
			name="type"
			type="string"
			required="true"
			hint="I am the Java data type being cast. I can be a core data type, a Java class. [] can be appended to the type for array conversions."
			/>

		<cfargument
			name="data"
			type="any"
			required="true"
			hint="I am the ColdFusion data type being cast to Java."
			/>

		<cfargument
			name="initHint"
			type="string"
			required="false"
			default=""
			hint="When creating Java class instances, we will be using your ColdFusion values to initialize the Java instances. By default, we won't use any explicit casting. However, you can provide additional casting hints if you like (for use with JavaCast())."
			/>

		<!--- Define the local scope. --->
		<cfset var local = {} />

		<!---
			Check to see if a type was provided. If not, then simply
			return the given value.

			NOTE: This feature is NOT intended to be used by the
			outside world; this is an efficiency used in conjunction
			with the javaCast() initHint argument when calling the
			toJava() method recursively.
		--->
		<cfif !len( arguments.type )>

			<!--- Return given value, no casting at all. --->
			<cfreturn arguments.data />

		</cfif>


		<!---
			Check to see if we are working with the core data types -
			the ones that would normally be handled by javaCast(). If
			so, we can just pass those off to the core method.

			NOTE: Line break / concatenation is being used here
			strickly for presentation purposes to avoid line-wrapping.
		--->
		<cfif reFindNoCase(
			("^(bigdecimal|boolean|byte|char|int|long|float|double|short|string|null)(\[\])?"),
			arguments.type
			)>

			<!---
				Pass the processing off to the core function. This
				will be a quicker approach - as Elliott Sprehn says -
				you have to trust the language for its speed.
			--->
			<cfreturn javaCast( arguments.type, arguments.data ) />

		</cfif>


		<!---
			Check to see if we have a complex Java type that is not
			an Array. Array will take special processing.
		--->
		<cfif !reFind( "\[\]$", arguments.type )>

			<!---
				This is just a standard Java class - let's see
				if we can invoke the default constructor (fingers
				crossed!!).

				NOTE: We are calling toJava() recursively in order to
				levarage the constructor hinting as a data type for
				native Java casting.
			--->
			<cfreturn createObject( "java", arguments.type ).init(
				this.toJava( arguments.initHint, arguments.data )
				) />

		</cfif>


		<!---
			If we have made it this far, we are going to be building
			an array of Java clases. This is going to be tricky since
			we will need to perform this action using Reflection.
		--->

		<!---
			Since we know we are working with an array, we want to
			remove the array notation from the data type at this
			point. This will give us the ability to use it more
			effectively belowy.
		--->
		<cfset arguments.type = listFirst( arguments.type, "[]" ) />

		<!---
			Let's double check to make sure the given data is in
			array format. If not, we can implicitly create an array.
		--->
		<cfif !isArray( arguments.data )>

			<!---
				Convert the data to an array. Due to ColdFusion
				implicit array bugs, we have to do this via an
				intermediary variable.
			--->
			<cfset local.tempArray = [ arguments.data ] />
			<cfset arguments.data = local.tempArray />

		</cfif>

		<!---
			Let's get a refrence to Java class we need to work with
			within our reflected array.
		--->
		<cfset local.javaClass = createObject( "java", arguments.type ) />

		<!---
			Let's create an instance of the Reflect Array that will
			allows us to create typed arrays and set array values.
		--->
		<cfset local.reflectArray = createObject(
			"java",
			"java.lang.reflect.Array"
			) />

		<!---
			Now, we can use the reflect array to create a static-
			length Java array of the given Java type.
		--->
		<cfset local.javaArray = local.reflectArray.newInstance(
			local.javaClass.getClass(),
			arrayLen( arguments.data )
			) />

		<!---
			Now, we can loop over the ColdFusion array and
			reflectively set the data type into each position.
		--->
		<cfloop
			index="local.index"
			from="1"
			to="#arrayLen( arguments.data )#"
			step="1">

			<!---
				Set ColdFusion data value into Java array. Notice
				that this step is calling the toJava() method
				recursively. I could have done the type-casting here,
				but I felt that this was a cleaner (albeit slower)
				solution.
			--->
			<cfset local.reflectArray.set(
				local.javaArray,
				javaCast( "int", (local.index - 1) ),
				this.toJava(
					arguments.type,
					arguments.data[ local.index ],
					arguments.initHint
					)
				) />

		</cfloop>

		<!--- Return the Java array. --->
		<cfreturn local.javaArray />
	</cffunction>

</cfcomponent>