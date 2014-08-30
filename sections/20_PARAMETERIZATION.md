# Token Parameterization

Curly braces are used to denote a parameter that Drillbridge should insert into
the query before executing. The contents of the curly braces should be a valid
JSON expression consisting of key/value pairs. Expressions can have the 
following properties: `name`, `expression`, `drillToBottom`, `sampleValue` and
`quoteMembers`.

## Property: name

The token in the expression can be given a name. This doesn't affect the 
execution of the token, it's more for reference/internal documentation. It does
have one particular use though. By giving the expression a  name, you will be
able to test the drill report more easily by plugging in your own values in 
the Test screen. The recommendation is to give the token a name matching the
dimension.

## Property: expression

The `expression` property is the most important and required property. The 
expression is a Spring Expression Language (SpEL) expression that gets parsed
into text that will become part of the SQL query.

## Property: drillToBottom

If set to `true`, Drillbridge will fetch the level-0 descendants of the queried
member from the associated Essbase outline. For example, if the member Qtr1 is
drilled from, Drillbridge will open the outline and get Jan, Feb, and Mar to 
put into the query.

Note: This will almost always require that the SQL query be 
written using an `IN` clause instead of the standard `=`.

## Property: sampleValue

This property doesn't affect the execution of the report. Rather, any value
given for the `sampleValue` will simply be used to pre-populate the text box
on the Test report screen. This is a convenience during development and can 
serve as a reminder of the expected value if you go to administer a report
that someone else created.

## Property: quoteMembers

The default for this property is true. The only recognized value for this
option is `false`. This option is taken into account only when drillToBottom is
set to `true` and members are pulled from an outline. 

For example, let's say that a user drills on a member in the outline called
`Qtr1`, and we want the query to actually run on `Jan`, `Feb`, and `Mar`. We 
would turn on `drillToBottom`, and when Drillbridge generates the query, it
will generate something like this:

	SELECT ... WHERE PERIOD IN ('Jan', 'Feb', 'Mar') AND ...
	
But what if we need numeric values in the `IN` clause? For example, let's say
instead of month names we have month numbers (01, 02, 03, etc) and the target
column in the database is numeric. In that case, we set `quoteMembers` to 
`false`, and the query would be this:

	SELECT ... WHERE PERIOD IN (01, 02, 03) AND ...

## Built-in Functions

	#monthAbbreviationToTwoDigits(String month)
	#monthAbbreviationToDigit(String month)
	#removeStarting(String prefix, String text)
	#removeEnding(String suffix, String text)
	
## Available Variables

Each member from the originally drilled data cell is available as a String 
variable to your expressions. The name of the variable is the a hash symbol
followed by the name of the dimension. If the dimension name has a space in it,
then that is converted to an underscore for purposes of creating a variable
name.

Dimension Name		Variable Name		Member/Variable Value Example
--------------		-------------		-----------------------------
Scenario			#Scenario			Actual
Time				#Time				Jan
Business Unit		#Business_Unit		BU345
Market				#Market				New York


Note that the value of the variable is a Java string object, so it doesn't 
matter if the variable has spaces in it. For example, if you were to use the 
#removeStarting function, the following produce exactly equivalent results:

	#removeStarting('BU', 'BU345') would return '345' 
	#removeStarting('BU', #Business_Unit) also returns '345' 
	
(Assuming that the member BU345 was drilled from in a dimension named Business Unit)
	
As noted below, the single quotes are not actually part of the value, they 
just denote that it's a single string.

	
## Query Examples

Consider a standard relational table named `SALES_TRANSACTIONS` with the 
following structure:

Column		Type			Example Value
------		----			-------------
YR			CHAR(2)			14
PD			CHAR(2)			01
MARKET		VARCHAR(32)		Washington
LOCATION	INTEGER			100
ACCOUNT		CHAR(4)			4110
AMOUNT		DECIMAL(13, 2)	3141.59
POST_DATE	DATE			2014-08-12

### A Simple Query

	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='14'

This is our reference query. It has no tokens in it so it is just executed as
it is. All rows with  year (YR) '14' (note the quotes indicating a character-
based field) will be returned, regardless of the period (PD) or other column.

### Adding in a Member From the Years Dimension

Let's now parameterize the query so that the value from the Years dimension of
a cube will be used instead of a fixed year.

	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='{{"name":"Years", "expression":"#Years"}}'

Drillbridge will replace everything between the curly braces, including the 
curly braces themselves, with a value that it generates based on the expression
and using the member drilled from in the Years dimension of the cube.

In other words if the members in the Years dimension of the cube are FY10, FY11,
FY12, FY13, and FY14 and the user drills from a data cell that is for FY14, then
the following is the resultant query:

	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='FY14'

When we drill from a cube, a variable for each source dimension is created that
we can then use in the query. In the parameterized query above, since there is
a Years dimension in the cube, a variable referred to by #Years is available to
us with the value of FY14.

This looks pretty good but something is not quite right -- the member in the 
cube is prefixed with FY but the value in the relational table does not have
this prefix. Therefore we need to find a way to map this. 

This can be accomplished in a couple of ways. One, it is possible to use SQL
itself. For example, the relational database may provide a function to get the
Right X characters of a string. Consider the following query:

	SELECT RIGHT('FY14', 2) 
	
For relational technologies that have a RIGHT function, this would generate the
value '14' from an input value of 'FY14'. In other technologies this may be a
SUBSTR function or something similar.

Because stripping a prefix off a member name is such a common transformation,
Drillbridge provide a built-in function to handle this. This is the
`#removeStarting` function. Given a prefix and an input value, this function 
will strip the prefix if the input value starts with it. If the input value 
does not start with the prefix, then it will be unchanged.

### Stripping a Prefix from a Member Name

We can now rewrite the query as follows:
 
 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='{{"name":"Years", "expression":"#removeStarting('FY', #Years)"}}'
 
Let's consider just the expression itself for a moment:
 
 	#removeStarting('FY', #Years)
 	
 Our function `removeStarting` is prefixed with a hash and it accepts two
 parameters – two _string_ parameters. Therefore we have enclosed the value FY
 with single quotes, in order to delimit that it's a string. The #Years variable
 is already a string (all inputs from the source cube are strings, even if they
 appear numeric), so we don't need quotes. In fact, it would be incorrect to
 use quotes around #Years because then it *wouldn't* be replaced properly –
 Drillbridge would think it's just a normal string!
 
 With the `#removeStarting` function now in place, when we drill from a member
 such as FY14, Drillbridge will now generate the following query:
 
 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='14'
 
 We're off to a good start -- we are now successfully using the drilled from 
 year in order to build our query. Now let's make things a little more
 complete. We don't just want to pull all of the entries for the entire year,
 it's also important to pull them from the correct period as well. 
 
### Converting Calendar Months
 
 Let's add on a period specification to our query that will use the value from 
 the Time dimension:
 
 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='{{"name":"Years", "expression":"#removeStarting('FY', #Years)"}}'
	AND PD='{{"name":"Time", "expression":"#Time"}}'
	
Let's say that we drill from a member at the bottom of the Time dimension called
'Jan'... the generated query would look like this:

 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='14' AND PD='Jan'

Again, that's promising but it's not quite right. In this example, the period
is a two-character column. Therefore, instead of January or Jan, we need '01'
(once again, note that since it's a fixed-width character column we have 
denoted the value in single quotes as well as added the padded zero. It would 
be incorrect in this case to use a value of '1' because that is distinctly 
different from '01'. 

Going from calendar months to numbers is presumed to be a very common operation,
so once again Drillbridge comes to the rescue with a convenience function that
helps out, rather than forcing us to resort to some pained SQL expression to
generate the proper value.

This time the function is named `#monthAbbreviationToTwoDigits` and it accepts
just one parameter. Given a value of 'Jan', this function will return a value 
of '01'. Let's now use it to transform thte given month from our query into 
the proper value:

	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR =
		'{{"name":"Years", "expression":"#removeStarting('FY', #Years)"}}'
	AND PD =
		'{{"name":"Time", "expression":"#monthAbbreviationToTwoDigits(#Time)"}}'

Drilling from a data cell with the year FY14 and the Time Jan will now result
in Drillbridge generating the following query:

 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='14' AND PD='01'

In cases where we don't need or want a two-digit character value, we can instead
use a sister function, `#monthAbbreviationToDigit`, which is exactly the same
but instead of generating 01, 02 and so on for Jan and Feb, the values 1 and 2
are generated.

## Drill-through from Upper Level Time Member

Drillbridge supports drilling from upper-level members in a couple of ways. The 
simplest method is to just use the member being drill from. For example, let's
consider when upper-level members can be drilled from in the cube and we have 
the following parameterized query:

 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='{{"name":"Years", "expression":"#removeStarting('FY', #Years)"}}'
	AND PD='{{"name":"Time", "expression":"#Time"}}'

Then, the user drills from a data cell with a year of FY14 and a time of Qtr1.
Drillbridge generates the following query:

 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='14' AND PD='Qtr1'

This probably isn't what we wanted (it might be, but it's likely that it's not).
What we need is the children (the level-0 children, to be exact) of the member
being drilled from in the Time dimension. So if the user drills from Qtr1, then
we want the query to pull for Jan, Feb, and Mar.

Let's change the query a little bit in order to do this.

	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR =
		'{{"name":"Years", "expression":"#removeStarting('FY', #Years)"}}'
	AND PD = '{{
		"name" : "Time",
		"expression" : "#monthAbbreviationToTwoDigits(#Time)",
		"drillToBottom" : "true"
	}}'

Make note of a couple of things. One is that I've now broken the query up into
multiple lines in order to aid in readability. There's nothing wrong with doing
this -- Drillbridge only cares about syntax and we can put in whitespace as much
as we want. I've added a new parameter, `drillToBottom`, and given it a value
of true. This parameter must be either `false` or `true`, with the default being
`false` (in other words, if we don't include the parameter then it's turned off
by default). 

When this parameter is turned on, there must be an associated cube to the
report. This is set in the Drillbridge report edit page (you may need to define
a server and then a cube mapping first). With the associated cube to the report,
when a drill-through request comes in, Drillbridge will open up the outline of
the associated cube and then grab all of the level-0 descendants of the given
member. In this case, the level-0 descendants of Qtr1 are Jan, Feb, and Mar.
Drillbridge then builds the query with these members, resulting in the 
following:

 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='14' AND PD='Jan', 'Feb', 'Mar'
	
THIS WON'T WORK! This is not valid SQL code. We need to use the SQL `IN` clause
if we have multiple inputs, not the `=` sign. Let's rewrite this query template:

	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR =
		'{{"name":"Years", "expression":"#removeStarting('FY', #Years)"}}'
	AND PD IN ({{
		"name" : "Time",
		"expression" : "#Time",
		"drillToBottom" : "true"
	}})

Note: We don't have single quotes around the code for PD now. The Drillbridge
query engine will automatically place quotes around each individual member
that is pulled from the outline. Drillbridge will now generate the following
query:

 	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR='14' AND PD IN ('Jan', 'Feb', 'Mar')
	
As of this writing, it's not possible to generate drill-through queries that
do not quote the members, in other words, you cannot generate a list of members
for the IN clause that are all numerical, such as WHERE PD IN (1, 2, 3). For
the time being you will need to treat the period as a character data item so 
that WHERE PD IN ('01', '02', '03') is a valid expression.

Things are looking good but we've kind of come back to an issue that we had 
before, which is that we can't query the database for 'Jan' or 'Feb', we instead
need the two-digit code for the month.

Not to worry! Let's just put the handy function around the parameter in our
expression:

	SELECT YR, PD, MARKET, LOCATION, ACCOUNT, AMOUNT, POST_DATE
	FROM SALES_TRANSACTIONS
	WHERE YR =
		'{{"name":"Years", "expression":"#removeStarting('FY', #Years)"}}'
	AND PD IN ({{
		"name" : "Time",
		"expression" : "#monthAbbreviationToTwoDigits(#Time)",
		"drillToBottom" : "true"
	}})

The key difference here is the expression that now contains the following:
`#monthAbbreviationToTwoDigits(#Time)`. Given that `drillToBottom` is turned
on, Drillbridge now does the following in order to generate the query:

1. Open up the outline and query for level-0 descendants of the given 
   Time member. E.g., if Qtr1 is drilled from, then Drillbridge grabs
   Jan, Feb, and Mar.
	   
2. Drillbridge then applies the given transformation to EACH member that
   was pulled from the outline. In this case, the values Jan, Feb, and Mar
   get converted to '01', '02', and '03'.
	   
3. The generated query is then executed against the data source as usual.
	

## Common Conversions

### Three character month to zero-padded number

Note that these functions also work on whole month names. 

Internationalization note: At this time, the months are hard-coded to English
month names. Support for localized month names is planned for a future release. 

Outline			DB Value		Conversion Expression  
---------------	---------------	--------------------------------------------
Jan				01				#monthAbbreviationToTwoDigits(#Time)
Feb				02				#monthAbbreviationToTwoDigits(#Time)

### Three character month to number without zero-padding

Outline			DB Value		Conversion Expression  
---------------	---------------	--------------------------------------------
Jan				01				#monthAbbreviationToDigit(#Time)
Feb				02				#monthAbbreviationToDigit(#Time)

### Remove prefix from member name

Outline			DB Value		Conversion Expression  
---------------	---------------	--------------------------------------------
FY14			14				#removeStarting('FY', #Year)
D100			100				#removeStarting('D', #Department)
DEPT_01			01				#removeStarting('DEPT_', #Department)

### Remove suffix from member name

Outline			DB Value		Conversion Expression  
---------------	---------------	--------------------------------------------
100_D			100				#removeEnding('_D', #Department)

### Remove prefix and add new prefix

Outline			DB Value		Conversion Expression  
---------------	---------------	--------------------------------------------
FY14			2014			'20' + #removeStarting('FY', #Year)


## A Query Example

The following report query is fairly involved with the mappings and options that it makes in order to translate from the members in a cube to data in a relational database. Following the query is an explanation of the transformations that are made.

	SELECT 
	    * 
    FROM
        TRANSACTIONS
    WHERE
    
        fiscal_year = '{{
        	"name":"Years",
        	"expression":"'20' + #removeStarting('FY', #Years)",
        	"sampleValue":"FY14"
        }}' AND
        
        fiscal_period IN ({{
        	"name":"Time",
        	"expression":"#monthAbbreviationToDigit(#Time)", 
        	"sampleValue":"Q1",
        	"drillToBottom":"true",
        	"quoteMembers":"false"
        }}) AND
        
        division = '{{
        	"expression":"#Location.substring(0, 3)"
        }}' AND
        
        location = '{{
        	"name":"Location",
        	"expression":"#Location.substring(4)", 
        	"sampleValue":"100-200"
        }}' AND
        
        dept = '{{
        	"name":"Dept",
        	"expression":"#removeStarting('0', #removeStarting('D', #Dept))",
        	"sampleValue":"D11"
        }}' AND
        
        account = '{{
        	"name": "Account",
        	"expression":"#removeStarting('0', #Account)", 
        	"sampleValue":"0170100"
        }}'
  
### Years

The Essbase cube has a dimension named Years that contains members such as FY10, FY11, FY12, FY13, and FY14. The relational table has a `CHAR(4)` column named `fiscal_year` containing values such as 2010, 2011, 2012, 2013, and 2014. Therefore, the conversion that needs to happy is to replace FY from the member with 20 (or more specifically, remove FY and then prepend 20 to the value to be queried). The expression to accomplish this is:

	'20' + #removeStarting('FY', #Years)
	
The `#removeStarting` function is a Drillbridge function that accepts text to remove from a string, and a string to remove it from. The `#Years` variable will be the member from the Years dimension. So if the user drills on FY14, then the function call part of the above expression is the equivalent of this:

	#removeStarting('FY', 'FY14')
	
Which generates this value:

	14
	
Then the string `20` (note the quotes around it which denote it as a string) is concatenated with the result of the function, generating the value of `2014`, which is then placed into the query.

### Time

The Time dimension mapping is the most complex in this query. The Essbase cube has a typical time dimension with members such as Qtr1, Qtr2, and Jan, Feb, and Mar. We want to enable drilling from upper members such as Qtr1, and also need to translate the month names because the value in the relational table is numerical. 

First thing first: The expression uses a built-in function to translate from month names to numbers:

	#monthAbbreviationToDigit(#Time)
	
So if the user drills on `Jan`, the function above will replace it with `1`. Next, on the expression itself note that drillToBottom is set to true, this is what turns on the drill feature in the first place (meaning that the Essbase outline associated with this report will be opened and check for level-0 descendants of the drilled-from member). Next, `quoteMembers` is set to `false`. This is because the value we are querying in the database is numeric. For example, let's this means that when the expression is replaced with the values from the query, it will be `(01, 02, 03)`. If `quoteMembers` was true, then it'd generate `('01', '02', '03')` instead, which would be wrong since that would be for a `CHAR` column rather than numeric.

Also note that on the previos entry for `fiscal_year`, the entire token (the stuff between {{ and }}) has single quotes on the outside, meaning that the token is replaced with the proper value and then placed in between the quotes. There are no quotes for this `fiscal_period` entry because it's numeric and the quotes go around the individual members on the inside of the parentheses.

Also note that we are using the `IN` clause. When Drillbridge replaces the contents of the token, since there will be possibly multiple items, we need to change the syntax of the query to be `IN` instead of `=`. It's okay to have only one thing in the `IN` clause.

### Division & Location

In the cube outline, there is one dimension for locations, with entries such as 100-200, indicating a division of 100 and a location of 200 in that division. In the source table (in this case), however, these are two separate columns. So in order to translate from a single member in the cube to the two values in the relational table, We need to break apart the member.

Since we can treat strings in the Drillbridge expression language as normal Java strings, we are able to use the standard Java `substring` method. Anything in Java is fair game, so check out the Java String documentation at http://docs.oracle.com/javase/7/docs/api/java/lang/String.html for more methods, if needed.

There are a couple variants of the `substring` method. The one we are using here is where we pass in two parameters: a starting character index and an ending character index. String indices start at 0 and end at the length of the string minus one. Therefore, to get the first X characters of a string, we pass in 0 (the beginning of the string) and in this case since we want the first three characters, we pass in 3 (this method does not include the character at the ending index, so passing in 0 and 3 gives us characters 0, 1, and 2 – meaning the left three characters of the string).

Note that the expression for the division mapping refers to #Location. Since all dimension members are available to each expression, we can refer to whichever values we need. 

The location mapping is similar to division, but we need the right three characters. We use the `substring` method again but this time use the variant where we just pass in the starting index... this method will then give us the string starting at that index and ending at the end of the string. So with an input of `100-200`, substring(4) gives us `200`.

### Dept 

Inside the cube, the Dept dimension contains members such as `D01`, `D02`, `D03`, `D20` and so forth. As an interesting quirk, the values in the relational table are 1, 2, 3, and 20. This means that simply stripping the D off the front isn't sufficient to get to the exact value we need to query in the database (because it's a text column, not numerical). As a little bit of a workaround or trick, we can use two calls to the built-in Drillbridge function `#removeStarting`. The first (inner) call will remove a beginning D on the member name, and the second (outer) call will remove a 0 from the beginning of THAT string, if present. 

### Account

Account gets a 0 stripped from the front because while thet member name in the cube may be `0170100`, the value in the database is a `CHAR` column that does not have a zero in front.
