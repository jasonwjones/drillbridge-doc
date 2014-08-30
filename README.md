# Drillbridge Documentation

The Drillbridge Documentation project is an open source documentation component of the Drillbridge project. While Drillbridge is not [at this time] an open source project itself, its documentation is.


## About the Files

Source (documentation) files are contained in the `sections/` subfolder. All files are Markdown. Files are prefixed with numbers to indicate their general order within the generated document. 

Images can be included in the `img/` folder. At present, only one image is used (a logo) but more could be included.


## How to Contribute

Clone the repository to your local machine, make edits, then create a pull request. You'll need to have a GitHub account. If you don't have one you can create one for free.


## Style Guide

It should be pretty straightforward to edit existing sections in terms of how to add a section, sub-section, bold text, and whatnot. For advanced features, the Pandoc Markdown help is useful. 

## Building the Documentation

Run the `gendoc.sh` script to generate a PDF file. You need to have Pandoc and a Tex distribution installed. On a Mac this can be accomplished by using `brew` to install Pandoc, then download the MacTex distribution.

Note that the table of contents is automatically generated.


## To Do List

In no particular order, a list of things that need/should be addressed:

* gendoc equivalent written in batch file in addition to .sh


## License

This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.