type options* = tuple
  fileSource, folderDestination, modName, modDescription: string
  verbose, quiet, writelogs, withmod, forcerewrite, nolatest, nocompression: bool
  groupid: int

const writeHelp* = "nwsync_write\p\p" &
  "This utility creates a new manifest in a serverside nwsync repository.\p\p" &
  "'Destination' is the storage directory into which the manifest will be written. A single destination can hold multiple manifests.\p\p" &
  "All given 'Sources' are added to the manifest in order, with the latest coming on top (for purposes of shadowing resources).\p\p" &
  "Each source will be unpacked, hashed, optionally compressed and written to the data subdirectory. This process can take a long time, so be patient.\p\p" &
  "After a manifest is written, the repository /latest file is updated to point at it. This file is queried by game servers if the server admin does not specify a hash to serve explicitly.\p\p" &
  "a 'Source' can be:\p" &
  "* a .mod file, which will read the module and add all HAKs and the optional TLK as the game would\p" &
  "* any valid other erf container (HAK, ERF)\p" &
  "* single files, including a TLK file\p" &
  "* a directory containing single files [Not Implemented in GUI]\p\p" &
  "Options:\p" &
  "Verbose - Verbose operation (>= DEBUG).\p\p" &
  "Quiet - Quiet operation (>= WARN).\p\p" &
  "With Module - Include module contents. This is only useful when packing up a module for full distribution.\pDO NOT USE THIS FOR PERSISTENT WORLDS.\p\p" &
  "No Latest - Don't update the latest pointer.\p\p" &
  "Name - Override the visible name. Will extract the module name if a module is sourced.\p\p" &
  "Description - Override the visible description. Will extract module description if a module is sourced.\p\p" &
  "Rewrite - Force rewrite of existing data.\pNOTE: Currently bugged in NWSync itself. No effect.\p\p" &
  "Disable Compression - By default, Compress repostory data. This saves disk space and speeds up transfers if your webserver does not speak gzip or deflate compression. Check to disable.\p\p" &
  "Group-ID - Set a group ID. Do this if you run multiple data sets from the same repository. Manifests with the same ID are considered for auto-removal by clients when superseded by a newer download. [default: 0]"

const pruneHelp* = "nwsync_prune\p\p" &
  "This utility will perform housekeeping on a nwsync repository.\p\p" &
  "Select the folder containing your NWSync manifest (\"Destination\") and it will:\p" &
  "- Make sure `latest` is a valid pointer, if present.\p" &
  "- Warns about manifests missing metadata.\p" &
  "- Prune all data files not contained in any stored manifests.\p" &
  "- Warn about missing data files.\p" &
  "- Clean up the directory structure.\p\p" &
  "Options:\p" &
  "Verbose - Verbose operation (>= DEBUG).\p\p" &
  "Quiet - Quiet operation (>= WARN).\p\p" &
  "Dry Run - Simulate, but don't actually do anything."

const printHelp* = "nwsync_print\p\p" &
  "This utility prints a manifest in human-readable form.\p\p" &
  "Select a specific manifest from your \"Destination\"\\manifests folder. Pick the file with no extension (not json).\p\p" &
  "Options:\p" &
  "Verbose - Verbose operation (>= DEBUG).\p\p" &
  "Quiet - Quiet operation (>= WARN)."
