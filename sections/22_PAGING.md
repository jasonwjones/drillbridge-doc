# Paging

As of Drillbridge 1.3.0, paging is now supported. More specifically, tokens
that help write paging queries in SQL are provided – paging is not done 
automatically. The reason that automatic paging is not supported is that while 
this approach ostenisbly means writing a bit of SQL code to perform the paging, it's
the most flexible and most performant.

If paging is turned on for a given report, then when that report is built, in
addition to the normal Point-of-View parameters that are made available to the
query, there will be three additional parameters:

* PAGE
* ROWS_PER_PAGE
* OFFSET

## PAGE Variable

Drillbridge will start the PAGE variable off with 1. This token can be used like
any other token.

## ROWS_PER_PAGE Variable

This value is configured on the report. Typical values might be 20, 50, 100,
500, or 1,000. 

## OFFSET Variable

The OFFSET variable is not specified in the report request, it is calculated as
a convenience variable to be used in queries. OFFSET is provided since in some
SQL dialects, the total number of rows to skip is needed rather than a page or
other option. The formula for OFFSET is: `(page - 1) * rowsPerPage`.

For example, if a report is meant to page on every 20 rows, meaning that page 1
is rows 1-20, page 2 is rows 21-40, and so on, the following would be true on 
page 2:

	PAGE = 2
	ROWS_PER_PAGE = 20
	OFFSET = (2 - 1) * 20 = 20
	
## Paging Query Example

### MySQL

This query would give results 11-20 from a MySQL (and PostgreSQL) table:

	SELECT column FROM table
	LIMIT 10 OFFSET 10
	
### Oracle

Really good information here: 

http://www.oracle.com/technetwork/issue-archive/2007/07-jan/o17asktom-093877.html


### SQL Server

Good info:

http://raresql.com/2012/07/01/sql-paging-in-sql-server-2012-using-order-by-offset-and-fetch-next/

