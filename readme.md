elasticblob
-----------

I wrote this little collection of ruby scripts in order to better search a mixed pile of PDFs, Word documents, HTML, and plain text. Built-in OS-level search is OK if you're looking for specific phrases in a document, but if you're looking for something more general (or fuzzy), a dedicated search service is needed.

Elasticsearch is simple enough to get started, and scales well. Is throwing attachments at it like this efficient? *No.* Base-64 encoding binary files takes up a lot of space -- but loading in more than a maybe ten thousand documents like this is a task for a proper, well-architected application, not a single ruby script. Go solve this problem yourself if you have a specific need for it.

How It Works
------------

Creating and filling an index:

`index.rb --index INDEX path1 path2 ...`

You must pass an index name; elasticblob won't try and guess. Every individual entity is of the type `document`, for consistency's sake. Elasticsearch 1.x must be installed and, for best results, have the [elasticsearch-mapper-attachments](https://github.com/elastic/elasticsearch-mapper-attachments) plugin activated. elasticblob also requires the [`elasticsearch-ruby` gem](https://github.com/elastic/elasticsearch-ruby).

Optional flags:

* `--endpoint HOST`: hostname and port where elasticsearch is running; defaults to `localhost:9200`.
* `--verbose`: print filenames as they are ingested.
* `--filetypes LIST`: a list of filetypes to ingest on the paths; defaults to `doc,docx,pdf,html,txt`.
* `--metadata FILENAME.yaml`: a metadata file of keys to add to a document. For example:

```
---
The Great American Novel.doc:
    title: The Great American Novel
    subtitle: Or, Evening Redness In The West
    author: Jonathan Doe
The Next Great American Novel.doc:
    title: The Next Great American Novel
    author: Jonathan Doe
    tags:
        - sequel
        - favorite
```

Avoid the use of leading underscores in key names, as this may conflict with internal elasticsearch identifiers.