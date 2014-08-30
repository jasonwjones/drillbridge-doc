# Smart Formatting

Drillbridge reports have a __Smart Formatting__ feature that can be turned on 
and off. If turned off, the data in a Drillbridge table does not receive any
formatting beyond having its value pulled from the database (this is the default
option).

If Smart Formatting is turned on, Drillbridge will inspect the types of data 
(the columns) that are returned from the SQL query and attempt to format them
to make their presentation nicer. This formatting applies to the following types
of columns:

* Date (DATE)
* Time (TIME)
* Timestamp (TIMESTAMP)
* Integer (BIGINT, INTEGER, SMALLINT)
* Decimals (DECIMAL, NUMERIC, DOUBLE, FLOAT)

Most notably, Drillbridge will not attempt to do any formatting to text-based
columns such as the following:

* Character (VARCHAR, NVARCHAR, CHAR, NCHAR)
* Text (TEXT, CLOB)
* Other types (BLOB, TINYINT, BIT)

Additionally, Drillbridge will take into consideration the locale of the user 
and try to format according to that. The locale is determined by the 
`Accept-Language` header submitted by the web browser.

## Date Formatting

Dates are formatted using the "SHORT" formatting type in Java, taking the 
current locale into consideration. For example, in English the date August 5th,
2014 is formatted as 8/5/14. In French this is 05/08/14.

## Time Formatting

Standard formatting in English (US) would look like: 3:53 PM. In French this
would appear as 15:53.

## Timestamp Formatting

Timestamp formatting is a combination of Date and Time formatting (the date 
format has a space and the formatted time appended to it), such as 05/08/14
15:53.

## Integer & Decimal Formatting

The precision and scale attributes of a numerical column will be inspected in 
order to determine how they should be formatted. Let's consider a column with a
type of DECIMAL(13, 2). In SQL parlance this means that the values can have 13
digits and 2 of those are to the right of the decimal. This can be used to 
represent typical currency values.

We'll say that the database value for a particular row is `1234567.1234`. With
Smart Formatting turned on, with an English web browser, this will output as:

	1,234,567.12

In a French locale, the output is:

	1 234 567,12 

Note the different grouping (thousands) and decimal separators.


## Circumventing Formatting

Drillbridge will not attempt to do any formatting on columns that have a
character-based type. If you need to use Smart Formatting but want to exclude
a column from getting formatted, then find a way to cast or otherwise convert
it to a string. For example, if you have a year value stored in an integer-based
column that represents the year and turn Smart Formatting on in the French 
locale, the output would be:

	2 014
	
Note that a space is the thousands or grouping separator in the French locale.
For U.S. English, Smart Formatting would convert the above value to the 
following:

	2,014
	
Either way, it's unlikely that this is the desired result. So to use Smart
Formatting in the report but not have it apply to this column, we just need to
cast it to a character using something like the following:

	SELECT TO_CHAR(AMOUNT) FROM DUAL
	
When Drillbridge interprets the SQL results, AMOUNT will appear as a VARCHAR 
instead of some integer type, and spaces/commas will not be added even with
Smart Formatting turned on.

## Other Quirks

Note that using ROUND() to round to a certain number of decimals does not affect
the scale that Drillbridge analyzes from the column. For example, if you have 
currency values stored in a column with a definition of `DECIMAL(13, 4)` such
that there are four places stored after the decimal but want Drillbridge to just
show two, then you would want to cast the value rather than round it. 

	SELECT CAST(AMOUNT AS DECIMAL(13, 2)) AS AMOUNT FROM DUAL
	
