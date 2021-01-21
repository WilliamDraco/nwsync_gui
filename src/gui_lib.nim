import os, osproc, streams, parsecfg, strutils
import nigui

const gui_version*: string = "1.2.0"

type
  Options* = ref object of RootObj
    fileSource*, folderDestination*, modName*, modDescription*, manifestSource*: string
    verbose*, quiet*, writelogs*, writeorigin*, withmod*, forcerewrite*, nolatest*, nocompression*, dryrun*: bool
    groupid*, filesizelimit*: int

proc writeConfig*(opt: Options) =
  var cfg: Config
  try:
    cfg = loadConfig(getAppDir() / "nwsync_gui.cfg")
  except:
    cfg = newConfig()

  cfg.setSectionKey("nwsync_write", "Source", opt.fileSource)
  cfg.setSectionKey("nwsync_write", "Destination", opt.folderDestination)
  cfg.setSectionKey("nwsync_write", "ModName", opt.modName)
  cfg.setSectionKey("nwsync_write", "ModDescription", opt.modDescription)
  cfg.setSectionKey("nwsync_write", "Verbose", $opt.verbose)
  cfg.setSectionKey("nwsync_write", "Quiet", $opt.quiet)
  cfg.setSectionKey("nwsync_write", "GroupID", $opt.groupid)
  cfg.setSectionKey("nwsync_write", "WriteLogs", $opt.writelogs)
  cfg.setSectionKey("nwsync_write", "WriteOrigin", $opt.writeorigin)
  cfg.setSectionKey("nwsync_write", "ForceRewrite", $opt.forcerewrite)
  cfg.setSectionKey("nwsync_write", "WithMod", $opt.withmod)
  cfg.setSectionKey("nwsync_write", "FileSizeLimit", $opt.filesizelimit)
  cfg.setSectionKey("nwsync_write", "NoLatest", $opt.nolatest)
  cfg.setSectionKey("nwsync_write", "NoCompression", $opt.nocompression)

  cfg.setSectionkey("nwsync_print", "ManifestSource", opt.manifestSource)

  cfg.setSectionKey("nwsync_prune", "DryRun", $opt.dryrun)

  cfg.writeConfig(getAppDir() / "nwsync_gui.cfg")

proc readConfig(): Options =
  var cfg: Config

  var opt: Options
  new(opt)
  try:
    cfg = loadConfig(getAppDir() / "nwsync_gui.cfg")
    opt.fileSource = cfg.getSectionValue("nwsync_write", "Source")
    opt.folderDestination = cfg.getSectionValue("nwsync_write", "Destination")
    opt.modName = cfg.getSectionValue("nwsync_write", "ModName")
    opt.modDescription = cfg.getSectionValue("nwsync_write", "ModDescription").convertLineBreaks
    opt.verbose = cfg.getSectionValue("nwsync_write", "Verbose").parseBool
    opt.quiet = cfg.getSectionValue("nwsync_write", "Quiet").parseBool
    opt.groupid = cfg.getSectionValue("nwsync_write", "GroupID").parseInt
    opt.writelogs = cfg.getSectionValue("nwsync_write", "WriteLogs").parseBool
    opt.writeorigin = cfg.getSectionValue("nwsync_write", "WriteOrigin").parseBool
    opt.forcerewrite = cfg.getSectionValue("nwsync_write", "ForceRewrite").parseBool
    opt.withmod = cfg.getSectionValue("nwsync_write", "WithMod").parseBool
    opt.filesizelimit = cfg.getSectionValue("nwsync_write", "FileSizeLimit", "15").parseInt
    opt.nolatest = cfg.getSectionValue("nwsync_write", "NoLatest").parseBool
    opt.nocompression = cfg.getSectionValue("nwsync_write", "NoCompression").parseBool

    opt.manifestSource = cfg.getSectionValue("nwsync_print", "ManifestSource")
    opt.dryrun = cfg.getSectionValue("nwsync_prune", "DryRun").parseBool
  except:
    return opt

  return opt

proc onLoad*(window: Window): Options=
  var process: Process
  try:
    process = startProcess(findExe("nwsync_write"), getAppDir(), @["--version"], nil, {poUsePath, poDaemon})
  except OSError:
    window.alert("Error: Ensure nwsync is in PATH or same directory as nwsync_gui.\n\n" & getCurrentExceptionMsg())
    window.dispose()
    return

  let output = process.outputStream.readAll()
  var nwsync_ver: string

  for line in output.splitLines():
    if line != "":
      nwsync_ver = line
  window.title = "NWSync GUI v" & gui_version & " - nwsync version: " & nwsync_ver

  return readConfig()


const writeHelp* = "nwsync_write - Developed for v0.3.1\p" &
  "This utility creates a new manifest in a serverside nwsync repository.\p\p" &
  "'Destination' is the storage directory into which the manifest will be written. A single destination can hold multiple manifests.\p\p" &
  "All given 'Sources' are added to the manifest in order, with the latest coming on top (for purposes of shadowing resources).\p" &
  "Each source will be unpacked, hashed, optionally compressed and written to the data subdirectory. This process can take a long time, so be patient.\p" &
  "After a manifest is written, the repository /latest file is updated to point at it. This file is queried by game servers if the server admin does not specify a hash to serve explicitly.\p\p" &
  "a 'Source' can be:\p" &
  "* a .mod file, which will read the module and add all HAKs and the optional TLK as the game would\p" &
  "* any valid other erf container (HAK, ERF)\p" &
  "* single files, including a TLK file\p" &
  "* a directory containing single files [Not Implemented in GUI]\p\p" &
  "Options:\p" &
  "Verbose - Verbose operation (>= DEBUG).\p" &
  "Quiet - Quiet operation (>= WARN).\p" &
  "With Module - Include module contents. This is only useful when packing up a module for full distribution.\pDO NOT USE THIS FOR PERSISTENT WORLDS.\p" &
  "No Latest - Don't update the latest pointer.\p" &
  "Name - Override the visible name. Will extract the module name if a module is sourced.\p" &
  "Description - Override the visible description. Will extract module description if a module is sourced.\p" &
  "Rewrite - Force rewrite of existing data.\p" &
  "Disable Compression - By default, Compress repostory data. This saves disk space and speeds up transfers if your webserver does not speak gzip or deflate compression. Check to disable.\p" &
  "Group-ID - Set a group ID. Do this if you run multiple data sets from the same repository. Manifests with the same ID are considered for auto-removal by clients when superseded by a newer download. [default: 0]\p" &
  "Limit File Size - Errors if any file exceeds the limit in mb. Note: The game client rejects any nwsync with a file above 15mb. [default: 15] \p" &
  "Write Origin - Write out .origin files, which can be used to reconstruct the hak structure from a manifest"

const pruneHelp* = "nwsync_prune - Developed for v0.3.1\p" &
  "This utility will perform housekeeping on a nwsync repository.\p\p" &
  "Select the folder containing your NWSync manifest (\"Destination\") and it will:\p" &
  "- Make sure `latest` is a valid pointer, if present.\p" &
  "- Warns about manifests missing metadata.\p" &
  "- Prune all data files not contained in any stored manifests.\p" &
  "- Warn about missing data files.\p" &
  "- Clean up the directory structure.\p\p" &
  "Options:\p" &
  "Verbose - Verbose operation (>= DEBUG).\p" &
  "Quiet - Quiet operation (>= WARN).\p" &
  "Dry Run - Simulate, but don't actually do anything."

const printHelp* = "nwsync_print - Developed for v0.3.1\p\p" &
  "This utility prints a manifest in human-readable form. Outputs as txt file next to source manifest.\p\p" &
  "Select a specific manifest from your \"Destination\"\\manifests folder. Pick the file with no extension (not json).\p\p" &
  "Options:\p" &
  "Verbose - Verbose operation (>= DEBUG).\p" &
  "Quiet - Quiet operation (>= WARN)."
