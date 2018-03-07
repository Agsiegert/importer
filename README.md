# importer

## WIP

Designed to work with [Scrivito exporter](https://scrivito.com/exporting-cms-content-d736d983591a5b39?_scrivito_display_mode=view&_scrivito_workspace_id=published)

* Run exporter 
* Add this import.rb file to your project, recomend in `/lib`
* Update path and file name of export file in importer (if changed)
* Switch Tenant keys to new tenant
* `rails runner lib/import.rb`
* Review error messages and determine if unfound objects are still needed.  Note these errors are generated due to the Model not being found in the current codebase. This is typically due to changing of code after content object creation. Example: `class Page` => `class CMS::Page`
* Start project `rails s` and move to `import workspace` Working Copy to determine if import was sufficiently successful.
