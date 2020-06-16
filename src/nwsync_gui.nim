import os, osproc, streams, parsecfg, strutils
import nigui
import gui_write, lib

const gui_version: string = "0.4.0"

proc writeConfig(opt: var options)
proc readConfig(): options
proc onLoad(): options

proc nwsyncWriteHelp()

app.init()

############### Window Definition
let window = newWindow("NWSync GUI v" & gui_version)
window.height = 700.scaleToDpi()
window.width = 600.scaleToDpi()

var opt = onLoad()

window.onCloseClick = proc(event: CloseClickEvent) =
  writeConfig(opt)
  window.dispose()

############### Primary container and top-buttons.
let containerPrimary = newLayoutContainer(Layout_Vertical)
window.add(containerPrimary)

let containerTopButtons = newLayoutContainer(Layout_Horizontal)
containerTopButtons.widthMode = WidthMode_Expand
containerTopButtons.xAlign = XAlign_Spread
let containerNWSyncButtons = newLayoutContainer(Layout_Horizontal)
let containerHelpButton = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerTopButtons)
containerTopButtons.add(containerNWSyncButtons)
containerTopButtons.add(containerHelpButton)
containerHelpButton.xAlign = XAlign_Right

let containerWrite = newLayoutContainer(Layout_Vertical)
containerPrimary.add(containerWrite)
containerWrite.hide()
generateWriteContainers(containerWrite, opt.addr)

let containerPrint = newLayoutContainer(Layout_Vertical)
containerPrimary.add(containerPrint)
containerPrint.hide()
#generateWriteContainers(containerWrite, opt.addr)

let containerPrune = newLayoutContainer(Layout_Vertical)
containerPrimary.add(containerPrune)
containerPrune.hide()
#generateWriteContainers(containerWrite, opt.addr)

let buttonWrite = newButton("NWSync Write")
containerNWSyncButtons.add(buttonWrite)
buttonWrite.onClick = proc(event:ClickEvent) =
  containerPrint.hide()
  containerPrune.hide()
  containerWrite.show()

let buttonPrune = newButton("Prune-ComingSoon") #("NWSync Prune")
containerNWSyncButtons.add(buttonPrune)
buttonPrune.onClick = proc(event:ClickEvent) =
  containerPrint.hide()
  containerWrite.hide()
  containerPrune.show()

let buttonPrint = newButton("Print-ComingSoon") #("NWSync Print")
containerNWSyncButtons.add(buttonPrint)
buttonPrint.onClick = proc(event:ClickEvent) =
  containerPrune.hide()
  containerWrite.hide()
  containerPrint.show()

let buttonHelp = newButton("Help")
containerHelpButton.add(buttonHelp)
buttonHelp.onClick = proc(event: ClickEvent) =
  nwsyncWriteHelp()

window.show()
app.run()


##########################################################################################
proc writeConfig(opt: var options) =
  var cfg: Config
  try:
    cfg = loadConfig(getAppDir() / "nwsync_gui.cfg")
  except:
    cfg = newConfig()

  cfg.setSectionKey("nwsync_write", "Source", opt.fileSource)
  cfg.setSectionKey("nwsync_write", "Destination", opt.folderDestination)
  cfg.setSectionKey("nwsync_write", "Verbose", $opt.verbose)
  cfg.setSectionKey("nwsync_write", "Quiet", $opt.quiet)
  cfg.setSectionKey("nwsync_write", "GroupID", $opt.groupid)
  cfg.setSectionKey("nwsync_write", "WriteLogs", $opt.writelogs)
  cfg.setSectionKey("nwsync_write", "ForceRewrite", $opt.forcerewrite)
  cfg.setSectionKey("nwsync_write", "WithMod", $opt.withmod)
  cfg.setSectionKey("nwsync_write", "NoLatest", $opt.nolatest)
  cfg.setSectionKey("nwsync_write", "NoCompression", $opt.nocompression)
  cfg.setSectionKey("nwsync_write", "ModName", opt.modName)
  cfg.setSectionKey("nwsync_write", "ModDescription", opt.modDescription)
  cfg.writeConfig(getAppDir() / "nwsync_gui.cfg")

proc readConfig(): options =
  var cfg: Config

  var opt: options
  try:
    cfg = loadConfig(getAppDir() / "nwsync_gui.cfg")
    opt.fileSource = cfg.getSectionValue("nwsync_write", "Source")
    opt.folderDestination = cfg.getSectionValue("nwsync_write", "Destination")
    opt.verbose = cfg.getSectionValue("nwsync_write", "Verbose").parseBool
    opt.quiet = cfg.getSectionValue("nwsync_write", "Quiet").parseBool
    opt.groupid = cfg.getSectionValue("nwsync_write", "GroupID").parseInt
    opt.writelogs = cfg.getSectionValue("nwsync_write", "WriteLogs").parseBool
    opt.forcerewrite = cfg.getSectionValue("nwsync_write", "ForceRewrite").parseBool
    opt.withmod = cfg.getSectionValue("nwsync_write", "WithMod").parseBool
    opt.nolatest = cfg.getSectionValue("nwsync_write", "NoLatest").parseBool
    opt.nocompression = cfg.getSectionValue("nwsync_write", "NoCompression").parseBool
    opt.modName = cfg.getSectionValue("nwsync_write", "ModName")
    opt.modDescription = cfg.getSectionValue("nwsync_write", "ModDescription").convertLineBreaks
  except:
    return opt

  return opt

proc onLoad(): options=
  var process: Process
  try:
    process = startProcess("nwsync_write", getAppDir(), @["--version"], nil, {
        poUsePath, poDaemon})
  except OSError:
    window.alert("Error: Ensure nwsync_write is in PATH or same directory as nwsync_gui.\n\n" & getCurrentExceptionMsg())
    window.dispose()
    return

  let output = process.outputStream()
  window.title = "NWSync GUI v" & gui_version & " - nwsync version: " & output.readline()

  return readConfig()



proc nwsyncWriteHelp() =
  window.alert("""nwsync_write - GUI updated for 0.2.5

  This utility creates a new manifest in a serverside nwsync
  repository.

  'Destination' is the storage directory into which the manifest will
  be written. A single destination can hold multiple manifests.

  All given 'Sources' are added to the manifest in order, with the
  latest coming on top (for purposes of shadowing resources).
  [Note: At present you cannot reorder Sources. New Sources are
  added to the bottom of the list.]

  Each source will be unpacked, hashed, optionally compressed
  and written to the data subdirectory. This process can take a
  long time, so be patient.

  After a manifest is written, the repository /latest file is
  updated to point at it. This file is queried by game servers
  if the server admin does not specify a hash to serve explicitly.

  a 'Source' can be:

  * a .mod file, which will read the module and add all HAKs and
    the optional TLK as the game would
  * any valid other erf container (HAK, ERF)
  * single files, including a TLK file
  * a directory containing single files [Not Implemented in GUI]


  Options:
  Verbose
    Verbose operation (>= DEBUG).

  Quiet
    Quiet operation (>= WARN).

  With Module
    Include module contents. This is only useful when packing up
    a module for full distribution.
    DO NOT USE THIS FOR PERSISTENT WORLDS.

  No Latest
    Don't update the latest pointer.

  Name
    Override the visible name. Will extract the module name
    if a module is sourced.

  Description
    Override the visible description. Will extract module
    description if a module is sourced.

  Rewrite
    Force rewrite of existing data
    NOTE: Currently bugged in NWSync itself. No effect.

  Disable Compression
    By default, Compress repostory data. This saves disk space
    and speeds up transfers if your webserver does not speak
    gzip or deflate compression. Check to disable.

  Group-ID
    Set a group ID. Do this if you run multiple data sets
    from the same repository. Manifests with the same ID
    are considered for auto-removal by clients when
    superseded by a newer download. [default: 0]""")
