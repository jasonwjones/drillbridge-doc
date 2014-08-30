# Custom Stylesheet/HTML Tips

Drillbridge allows custom styling in a few different ways. It is possible to specify a global stylesheet that affects all reports, as well as report-specific options including stylesheets, header, and footer.

## Global Stylesheet

The global stylesheet server setting will be added to every report that is run from the server. This allows for easily customizing the apperance of every report.

## CSS "Hooks"

Drillbridge report data tables are generated with specific CSS classes in order to allow the table, rows, and specific columns to be easily formatted.

The single data table for the report data has a CSS class of `drillbridge-table`.

Each row in the data table has a class of `dr`. Odd rows in the table will additionally have a class of `odd`. This makes it easy to do custom styling for alternating rows.

Each column in the data table has a class of `dc` as well as a class of `dc-X` where X is the column index. Note that column indices start at 1. So in a 10 column table the classes would be `dc-1`, `dc-2`, ..., `dc-10`.

## Header & Footer

Each report can have a custom header and footer. You can include arbitrary HTML in these blocks. This custom HTML/text will be placed inside of a `<div>` block at the top and bottom of the page. The header contents will be inside the following block:

	<div class="header">
		Your custom HTML
	</div>
	
Similarly, the footer text will be placed in this block near the end of the page:

	<div class="footer">
		Your custom HTML
	</div>

You can use custom image tags and other external items so long as they are hosted somewhere on the network that is accessible via the typical web-browser session (i.e., Drillbridge itself cannot host custom images or files).

