# Overview

Drillbridge provides support for setting up drill-through from an Essbase cube 
to a relational database source. It accomplishes this by creating and executing
a SQL query that is based on the point of view that a user drills from. For 
example, if a user drills from a member cell at the intersection of January, 
Sales, and Washington (such as from the Sample/Basic database), then Drillbridge
understands that the following parameters exist and can be used to build the SQL
query:

*	Year: January
*	Measure: Sales
*	Market: Washington

When Drillbridge goes to create the actual query used to query against the 
drill-through report’s associated connection, it’ll replace tokens with the 
values from the drill-through intersection.

## Prerequisites

There are only a couple of things you need in order to install Drillbridge. The target server should be 64-bit, and Java 1.6+ must be on the PATH.

### 64-bit Windows 

At the moment, Drillbridge is only tested on 64-bit Windows servers. In theory in the long run it should run fine on Linux/Unix servers and even on 32-bit servers but this is not tested/supported at the moment.

### Java

Java should be available on the PATH. In other words, if you open a command prompt and type the following:

	java –version

You should see output indicating that Java is installed (rather than some error message). Frequently Java is not on the PATH, in which case you can add it by finding the folder containing java.exe and adding that to the PATH environment variable.

## Installation

Extract the Drillbridge zip file to the folder that it will reside in. A recommended folder is C:\\Drillbridge or D:\\Drillbridge.

In the \\bin subfolder, try running the following:

	Drillbridge.bat console
	
This will attempt to run the Drillbridge service without installing it first. The point of doing this is to verify that the service works properly and to scan for any errors. If Drillbridge starts up successfully then you could be able to access it at the following URL:

	http://localhost:9220
	
If the Drillbridge service comes up in your web browser, it should be okay to install it as a service. Stop the service by pressing Ctrl+C.

Now install the service:

	Drillbridge.bat install

Now start it (you can also start it from Windows Services):

	Drillbridge.bat start

The default username and password to login to Drillbridge is “admin” and password “drillbridge”.

## Uninstalling

If at some later point you need to uninstall, run this command (make sure not to delete the Drillbridge files first):

	Drillbridge.bat remove

# Configuration Overview

At a high level, the process of setting up a drill-through report is as follows:

1.	Create a connection
2.	Create a report
3.	Configure Essbase cube to point to the report URL

Step 3 can be accomplished in a couple of ways. The manual approach is to 
open Essbase Administration Services, navigate to the cube that you want to
setup drill-through on, and select the Edit > Drill-through Definitions menu.
This menu allows you to setup one or more drill-through reports on a given cube.

Newer versions of Drillbridge can help with this process if you set things up
properly. This process involves using the Drillbridge interface to define an 
Essbase server, cube mapping and "deployment specification", then using the 
Deploy option on a configured report to automatically deploy it.

## Creating a Connection

A connection is created to a relational database. Out of the box, Drillbridge has support for Oracle, Microsoft SQL Server, and MySQL databases. Support for additional database types can be added (see Adding Third-Party JDBC Drivers section).

To create a new connection, you must specify the following values:

*	**Name**. This is not seen by end-users – just provide yourself with a sensible name that makes selecting the connection from a report easy.
*	**JDBC URL**. JDBC URLs are different depending on the type of technology used. They include the technology type, server name, database name, and possibly other parameters.
*	**Username**. The name to use when connecting to the database. 
*	**Password**. The password for the user to use when making a connection to the database.

## Creating a Report

A report is created with a name, a connection (selected from the list of connections), and a SQL query template. The name given to a report will be displayed when the report is created from a drill-through operation.
The SQL query provided must be compatible with the connection technology. For example, if the connetion is a Microsoft SQL Server database, then the query written must be valid for that technology. 
Here is an example query that has been parameterized:

	SELECT
	    PERIOD, ACCOUNT, PRODUCT, MARKET, AMOUNT
	FROM
	    SAMPLE_FACT_DRILL
	WHERE 
		PERIOD  = '{{ "name" : "Year",    "expression": "#Year"      }}' AND 
		ACCOUNT = '{{ "name" : "Account", "expression": "#Account" }}}}' AND
		PRODUCT = '{{ "name" : "Product", "expression": "#Product" }}}}' AND
		MARKET  = '{{ "name" : "Market",  "expression": "#Market"  }}}}'
	    
_Note_: Be careful copying and pasting from this document to a report, the double-quotes may not be the right type – in this document you see “smart-quotes” whereas a normal query should have “regula” double-quotes.
The preceding query has four parameters in it – Year, Measures, Product, and Market. This query will expect to be drilled to from a cube with at least these dimensions in it (for example, the Sample/Basic cube has all four of these dimensions as well as extras). If the cube used to drill to the query does not have all of the required dimension, Drillbridge will report an error because it is unable to build the whole query.

## Report Tokens & Parameters

Curly braces are used to denote a parameter that Drillbridge should insert into the query before executing. The contents of the curly braces should be a valid JSON expression consisting of key/value pairs. 

## Creating Deployment Specifications

Deployment specifications are used when deploying drill-through definitions to an Essbase cube. The main thing to know about these are that each _line_ in the region definition corresponds to a drill region that you'd see in the EAS drill-definition editor.

### Name

Give a name to the deployment specification. Deployment specifications are separate from reports because you may want to use the same deployment specification for multiple reports. 

If there are multiple drill-through reports for a given data cell, then SmartView will show the names of the deployment specifications that are available. For this reason, you will likely want to give your deployment specification a meaningful name for users.

### Level-0

Turn this option on if the drill report definition should only be available for cells that are at level zero – that is, at level zero for every dimension. You still need to define a member definition.

### Member Definition

The member definition is similar to a `FIX` statement in a calc script. It is used to define the members that should be active for a given drill report. In EAS, you are able to define multiple drill regions by creating different entries in a list box. In Drillbridge, when you edit the deployment specification, the different entries go on different lines in the text box. Drillbridge will process each line in the member definition box and translate it to different drillable regions as if it were different entries in the list box in EAS.

A way to think about the member definition is that you are defining the members from each dimension that will be active for drilling to the given report. For example, consider the following definitino which for formatting reasons is multiple lines but should actually be thought of as just ONE LINE in a drill region definition:

	@IDESCENDANTS("Time"), @CHILDREN("Years"), 
	@RELATIVE("Location", 0), @RELATIVE("Dept", 0), @RELATIVE("Account", 0)

This example assumes that there is a five-dimensin cube with dimensions Time, Years, Location, Dept, and Account. The level-0 option is turned off. We are effectively declaring that the given report is active for cells that have all of the following true:

* The member from the Time dimension is one of the members returned by `@IDESCENDANTS("Time")`
* It is a child of the member Years (meaning that it is one of FY10, FY11, and so on or whatever the children of the Years dimension are)
* It is a level-0 member of the Location dimension
* It is a level-0 member of the Dept dimension
* It is a level-0 member of the Account dimension

Do note that it's not always necessary to include a definition for each dimension. In fact, the drillable region definitino will frequently be simpler. For example, if the cube mentioned above had a Scenario dimension and we only wanted to enable drilling on the child Actual of the Scenario dimension, and level-0 combinations for every other dimension, then we could just turn on level-0 only and then set the drillable region definition simply as "Actual". If you don't define a member definition for a particular dimension, then Essbase assumes that all members for that dimension are drillable. However, if the level-0 option is on then you end up with just the level-0 members of dimensions with no specification. 

If you are unsure about your drillable region definition and getting it setup correctly, it is recommended that you change your SmartView options to highlight the drillable data cells in some obvious way (such as background color yellow), then drill into the cube to see what cells "light up" as being drillable. You may find that the definition of drillable regions for cells if "too loose" or "too tight" – in other words, you may find that more cells than you want are marked as drillable, or fewer cells than you want are marked as drillable. You can make changes to the drillable region in EAS, save them, then refresh in SmartView to check out your changes. You do not need to stop and start the cube.

## Automatic Definition Deployment

Create a new Essbase Server definition inside of Drillbridge, then create a new cube mapping to a cube such as Sample Basic. Next, create a Deployment Specification. Enter a name such as “Default” for the spec, then enter the list of members for the drill regions. Separate different regions with newlines, then check whether it should be a level-0 report only or not.
Lastly, from the Report editor, choose the Deploy tab and then select the cube, deployment spec, and enter the server name to deploy to. After this is done you will likely want to verify the definition by following the instructions from the next section and logging in to EAS.

### Server Name

The server name text box should be filled in with the network name of the server with Drillbridge as well as the port that Drillbridge is on. For example, if Drillbridge is installed on drill01.corp.saxifrages.com using the standard Drillbridge port, then you would enter `drill01.corp.saxifrages.com:9220` in this box and then deploy. If you need to edit this entry you can do so from the Drillthrough definitions in EAS.

## Manually Configuring or Adjusting Existing Definition

The Essbase Administration Services (EAS) Console is used to define drill-through definitions for a report. Login to EAS as normal, go to the cube to add a drill-through definition to, and the right click to select Edit → Drill-through Definitions.
A screen will come up where you must give the drill-through report a name, configure the drillable members, and then define an XML definition.

The drill-through XML definition will generally look like the following:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<foldercontents path="/">
 <resource name="Assets Drill through GL" description=""
   type="application/x-hyperion-applicationbuilder-report">
  <name xml:lang="fr">Rapport de ventes</name>
  <name xml:lang="es">Informe de ventas</name>
  <action name="Display HTML" 
 	description="Launch HTML display of Content" shortdesc="HTML">
   <url>
    <![CDATA[http://server:9220/drill/1/v2?sso=$SSO_TOKEN$&$ATTR(ds,pos,gen,level.edge)$]]>
   </url>
  </action>
 </resource>
</foldercontents>
```

Note that this example has the option `<name>` tags in it. Check the Code tab on the Report editor though for the current definition. Current versions do not include these tags but advanced users may wish to refer to this and add them in.

## Drillbridge Server Options

### Global Stylesheet

Global stylesheet allows you to define CSS code that will appear inside of `<style></style>` tags on each generated report. This allows you to global adjust things such as table spacing, colors, and more. You can also adjust styles for individual reports if need be (on the given report's configuration page).

### Force check SSO token against server

**Version Note**: This feature is not turned on as of 1.3.0. It should be ready for future versions.

Turning this option on forces a stronger security check for drill operations.

### Use Session Pinning for POV from User App

Turning this option on causes the server to associate the drilled-from POV from a SmartView/Planning drill operation to a uniquely generated session ID. Subsequent drill requests must then be for that POV.

Essentially what this option provides is the ability to lock down a POV to a certain session so that a user can't change parameters in the URL and drill to data that they shouldn't be able to see. For example, if the original POV that is drilled from was for a certain location, an intrepid user might notice part of the parameters in the URL as containing `Location=100`. They might then change it to be `Location=200` to try and cause a SQL request to be executed and fetch data that they wouldn't otherwise have access to. Sesssion pinning locks the POV to the session when it is generated from SmartView or Planning.

### Use Essbase Outline Caching

**Version Note**: This feature is not turned on as of 1.3.0. It should be ready for future versions.

For reports with a drill-to-bottom member (such as allowing the user to drill on Qtr1 and have a query be executed for Jan, Feb, and Mar), the outline must be opened and queried for the level-0 descendants of the given member. Normally this operation runs quickly, however, in some cases it may be needed or desireable to cache the results of the outline so that subsequent requests can skip opening the outline and instead just use the cache. 

The results of the first Essbase outline query for each member that needs to be query will be cached for the number of seconds specified in the configuration setting. 

Future versions may offer the ability to cache the entire outline so that even the first query does not have a performance penalty associated with it.

### Maximum Number of Descendants on Essbase Drill

This option limits the number of members that will be returned from an Essbase outline query operation. This may be useful for relational databases that limit the number of items that can be placed in an `IN` clause. (Some versions of Oracle have a limit of 1,000 items).

**Note**: No messages or information will be displayed if more than the specified number of members is encountered. Drillbridge will simply silently truncate the number of members and execute the query. So be warned that this option is simply to prevent queries from failing that would otherwise fail due to too many entries in an `IN` clause.

## Procedures

The following section lists actions you may wish to perform on your installation
of Drillbridge and how to do them.

### Adding Third-Party JDBC Drivers

Out of the box, Drillbridge includes drivers for Oracle databases, Microsoft 
SQL Server, and MySQL. It is possible to support additional database types. 
Simply include the Java JDBC JAR file for your database under the /drivers 
folder, then restart the Drillbridge server.

Note that databases beyond Microsoft SQL Server, Oracle, and MySQL are not 
really tested much for compatibility with Drillbridge. If you run into an issue
with your version of database please report it.

### Change Drillbridge Server Password

Edit the configuration file to change the value for the `dtb.password` parameter.

### Upgrading Drillbridge

Unless other instructions are otherwise provided, upgrading Drillbridge should be done as follows:

1.	Stop Drillbridge service
2.	Make a backup of the contents of the Drillbridge folder (such as C:\\Drillbridge or D:\\Drillbridge
3.	Uninstall the Drillbridge service by going to the bin folder and running Drillbridge remove
4.	Rename the Drillbridge folder
5.	Unzip new Drillbridge distribution to same location as previous Drillbridge installation
6.	Copy Drillbridge.h2.db from old Drillbridge installation to new Drillbridge installation (replace existing)
7.	Run new Drillbridge install command
8.	Start the Drillbridge service as normal

