\newpage

# Release History

## Version 1.3.1

* Updated deployment code to explicitly include "id" parameter (should fix several drill issues from Planning)
## Version 1.3.0

This is a major release! There are _tons_ of new and enhanced features in this
release. Major features of this release:

* Connection testing has been reworked and should now work on Oracle databases
* Implement debug mode -- can put reports into this mode to just show the generated query but not run it
* Can now set a global stylesheet for all reports that are built (use to adjust spacing, etc)
* Can now add/edit/delete variables (both user and system -- be careful!)
* New option to paginate results, provide PAGE, ROWS_PER_PAGE, and OFFSET variables to report 
* Ability to use variables in queries -- global variables are prefixed with DR_. E.g., variable "server" can be accessed in query as #DR_server"
* Rows and columns in drill report page now have CSS classes
* Can add custom styles to individual reports -- allows for some customization of how the report, table, rows, and columns will be displayed (might want text-align: right for numerics and such)
* Database query now respects the row limit so the max rows can be capped
* Reports now have a configurable query timeout value to limit the max number of seconds a query can run for. 0 is default.
* Excel columns will now autosize (more improvements coming to Excel generation to fix text vs number problem)
* Enhance logs to show queries that are constructed
* Drills now quick-redirect to another page in order to improve Refresh, Previous, and Next page semantics (prevents resubmitting POSTed data, improves future features)
* Include custom header and custom footer on report (supports HTML)
* Drill-through definition XML is updated! Include fix for the SSO token
* Formatting issues that are closed by way of custom stylesheets:
	* Amount column should be right-aligned. 
	* Space between 2 lines is too large 
	* add a little bit more of contrast between the background colour of 2 lines in the report 
* Deployment Specs can now have a description
* Should respect Locale for various column types:
	* Date
	* Timestamp/Time
	* Decimal/Double/Float
	* Integer/Numeric/BigInt
* Localization: localize into French!
* Implement statistics for tracking how much reports are being used
* Excel download filename is now based on the name of the report
* Drilling to descendants of a member is now limited to 1,000 members. This may be revised in the future but for now is meant to protect IN clauses for Oracle databases that don't support more than 1000 items.
* Removed Refresh button since it is now possible to use the browser refresh thanks to some under the hood improvements for pagination
* Use the associated EssbaseCube (and therefore server) to validate SSO token
* Move Connections/Reports to admin/ URL tree for cleaner security implementation
* Now use connection name instead of description
* Member drilling occurs under the credentials of the mapped user (typically admin) which means that the members pulled back are based on their credentials (in other words, members are not pulled with the credentials of the user performing the drill operation)
* Allow new parameter on token, 'sampleValue' that allows to specify a default value to aid in testing (this value shows up on the test page, but doesn't affect the execution of the report in any way)
* In anticipation of some possibly long Oracle RAC and other verbose JDBC URLs, the JDBC connection string limit has been raised from 255 characters to 4000

Known issues in this release:

* Essbase outline caching not enabled in this release

## Version 1.0.2

*	Include SQL Server file for integrated authentication
*	Can now edit server, cube, and deployment spec definitions
*	Include new expression language
*	Drill to children on Essbase cube works
*	Row limit on drill reports
*	Debug mode on drill reports

## Version 1.0.1

Some minor and not so minor updates:

*	Update SQL Server JDBC driver to latest version
*	Fix for when query has no parameters in it
*	Notes about Java being required on the PATH
*	Added EULA
*	Query size can now be 4000 characters (was 255)
*	Parsing of payload from SmartView drill operation is now more robust
*	Cleaned up logging to try and reduce clutter a bit
*	Removed several unused/test dependencies, shaving 13MB off download
*	Now includes Oracle driver (thin client)
*	Show examples of JDBC URLs on connection creation screen
*	Note: Essbase Servers and Deployment Specs are still unused/unusable in this release.  Reports need to be deployed manually
*	Upgraded several dependencies to newer versions

## Version 1.0.0

This is the initial public release of Drillbridge. Certain features are disabled for now:

*	Support for drilling to level-0 members from an upper level member
*	Automatically deploying reports to an Essbase cube

# Thanks

A special thank you is given to those that have tested, provided comments, 
suggestions, feedback or support in some form:

*	Evgeniy Rasyuk
*	Paul Turner
*	Julien Cardon
