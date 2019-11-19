import os, osproc, streams, parsecfg, strutils
import nigui


var fileSource, folderDestination, modName, modDescription: string
var verbose, quiet: bool
const gui_version: string = "0.1.0"

proc writeConfig()
proc readConfig()
proc onLoad()
proc nwsyncWrite()
proc chooseSource()
proc chooseDestination()
proc nwsyncWriteHelp()

app.init()


var window = newWindow("NWSync GUI v" & gui_version)
window.onCloseClick = proc(event: CloseClickEvent) =
  writeConfig()
  window.dispose()

onLoad()

var containerPrimary = newLayoutContainer(Layout_Vertical)
window.add(containerPrimary)

var containerTopButtons = newLayoutContainer(Layout_Horizontal)
containerTopButtons.widthMode = WidthMode_Expand
containerTopButtons.xAlign = XAlign_Spread
var containerNWSyncButtons = newLayoutContainer(Layout_Horizontal)
var containerHelpButton = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerTopButtons)
containerTopButtons.add(containerNWSyncButtons)
containerTopButtons.add(containerHelpButton)
containerHelpButton.xAlign = XAlign_Right

var buttonWrite = newButton("NWSync Write")
containerNWSyncButtons.add(buttonWrite)
buttonWrite.onClick = proc(event: ClickEvent) =
  nwsyncWrite()

var buttonPrint = newButton("Print-ComingSoon") #("NWSync Print")
containerNWSyncButtons.add(buttonPrint)

var buttonPrune = newButton("Prune-ComingSoon") #("NWSync Prune")
containerNWSyncButtons.add(buttonPrune)

var buttonHelp = newButton("Help")
containerHelpButton.add(buttonHelp)
buttonHelp.onClick = proc(event: ClickEvent) =
  nwsyncWriteHelp()

var containerSourceDestination = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerSourceDestination)
containerSourceDestination.widthMode = WidthMode_Expand
containerSourceDestination.maxHeight = 120

var containerSource = newLayoutContainer(Layout_Vertical)
containerSourceDestination.add(containerSource)

var textareaSource = newTextArea()
textareaSource.text = "Chosen file:\p" & fileSource
containerSource.add(textareaSource)
textareaSource.editable = false
textareaSource.wrap = true
textareaSource.height = 60
textareaSource.widthMode = WidthMode_Expand

var buttonChooseSource = newButton("Choose Source...")
containerSource.add(buttonChooseSource)
buttonChooseSource.onClick = proc(event: ClickEvent) =
  chooseSource()

var lableSourceLimit = newLabel("Currently only supports passing a single file")
containerSource.add(lableSourceLimit)

var containerDestination = newLayoutContainer(Layout_Vertical)
containerSourceDestination.add(containerDestination)

var textareaDestination = newTextArea()
containerDestination.add(textareaDestination)
textareaDestination.text = "NWSync Destination:\p" & folderDestination
textareaDestination.editable = false
textareaDestination.wrap = true
textareaDestination.height = 60
textareaDestination.widthMode = WidthMode_Expand

#choose destination button with event here, but cannot choose folder yet(nugui limit)
var buttonChooseDestination = newButton("Choose Destination...")
containerDestination.add(buttonChooseDestination)
buttonChooseDestination.onClick = proc(event: ClickEvent) =
  chooseDestination()

var containerModName = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerModName)
containerModName.frame = newFrame("Module Name (blank = extracts from module source if possible)")
var textboxModName = newTextBox(modName)
containerModName.add(textboxModName)
textboxModName.minWidth = 400

var containerModDescription = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerModDescription)
containerModDescription.frame = newFrame("Module Description (blank = extracts from module source if possible)")
containerModDescription.maxHeight = 100
var textareaModDescription = newTextArea(modDescription)
containerModDescription.add(textareaModDescription)
textareaModDescription.minHeight = 25
textareaModDescription.maxHeight = 75

var containerCheckboxes = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerCheckboxes)

var checkboxVerbose = newCheckbox("Verbose Output")
containerCheckboxes.add(checkboxVerbose)
var checkboxQuiet = newCheckbox("Quite Output")
containerCheckboxes.add(checkboxQuiet)

checkboxVerbose.onClick = proc(event: ClickEvent) =
  if checkboxVerbose.checked == false:
    verbose = true
    if checkboxQuiet.checked == true:
      checkboxQuiet.checked = false
      quiet = false
  else:
    verbose = false

checkboxQuiet.onClick = proc(event: ClickEvent) =
  if checkboxQuiet.checked == false:
    quiet = true
    if checkboxVerbose.checked == true:
      checkboxVerbose.checked = false
      verbose = false
  else:
    quiet = false

var taNWSyncOutput = newTextArea()
var containerOutput = newLayoutContainer(Layout_Vertical)
containerPrimary.add(containerOutput)
containerOutput.frame = newFrame("Output")
containerOutput.heightMode = HeightMode_Expand

containerOutput.add(taNWSyncOutput)
taNWSyncOutput.editable = false
taNWSyncOutput.wrap = true

window.show()
app.run()



##########################################################################################
proc writeConfig() =
  var cfg: Config
  try:
    cfg = loadConfig(getAppDir() / "nwsync_gui.cfg")
  except:
    cfg = newConfig()

  cfg.setSectionKey("nwsync_write", "Source", fileSource)
  cfg.setSectionKey("nwsync_write", "Destination", folderDestination)
  cfg.setSectionKey("nwsync_write", "Verbose", $verbose)
  cfg.setSectionKey("nwsync_write", "Quiet", $quiet)
  modName = textboxModName.text
  cfg.setSectionKey("nwsync_write", "ModName", modName)
  modDescription = textareaModDescription.text
  cfg.setSectionKey("nwsync_write", "ModDescription", modDescription)
  cfg.writeConfig(getAppDir() / "nwsync_gui.cfg")

proc readConfig() =
  var cfg: Config

  try:
    cfg = loadConfig(getAppDir() / "nwsync_gui.cfg")
    fileSource = cfg.getSectionValue("nwsync_write", "Source")
    folderDestination = cfg.getSectionValue("nwsync_write", "Destination")
    verbose = cfg.getSectionValue("nwsync_write", "Verbose").parseBool
    quiet = cfg.getSectionValue("nwsync_write", "Quiet").parseBool
    modName = cfg.getSectionValue("nwsync_write", "ModName")
    modDescription = cfg.getSectionValue("nwsync_write", "ModDescription")
  except:
    return

proc onLoad() =
  var process: Process
  try:
    process = startProcess("nwsync_write", getAppDir(), @["--version"], nil, {
        poUsePath, poDaemon})
  except OSError:
    window.alert("Error: " & getCurrentExceptionMsg() & "\n\nnwsync_write should be in PATH or same directory as nwsync_gui")
    window.dispose()
    return

  var output = process.outputStream()
  window.title = "NWSync GUI v" & gui_version & " - nwsync version: " &
      output.readline()

  readConfig()

proc chooseSource() =
  var dialog = newOpenFileDialog()
  dialog.title = "Choose Source"
  dialog.multiple = false
  dialog.directory = getHomeDir() / "documents/neverwinter nights/modules"
  dialog.run()

  if dialog.files.len == 0:
    window.alert("Please choose a source file")
    return

  filesource = dialog.files[0]
  textareaSource.text = "Chosen file:\p" & fileSource

proc chooseDestination() =
  var dialog = newSelectDirectoryDialog()
  dialog.title = "Choose Destination"
  dialog.startDirectory = getAppDir()
  dialog.run()

  if dialog.selectedDirectory == "":
    window.alert("Please choose a destination folder")
    return

  folderDestination = dialog.selectedDirectory
  textareaDestination.text = "NWSync Destination:\p" & folderDestination

proc constructArgs(): seq[string] =
  if folderDestination == "":
    window.alert("Please select a destination folder")
    return
  elif fileSource == "":
    window.alert("Please select at least one Source File")
    return

  if verbose == true:
    result.add("-v")
  elif quiet == true:
    result.add("-q")

  modName = textboxModName.text
  result.add("--name=\"" & modName & "\"")
  modDescription = textareaModDescription.text
  result.add("--description=\"" & modDescription & "\"")

  result.add(folderDestination)
  result.add(fileSource) #in future will be a for-loop to include all sources

proc nwsyncWrite() =
  var args = constructArgs()

  if args == @[]:
    return

  var process = startProcess("nwsync_write", getAppDir(), args, nil, {poUsePath, poDaemon})
  var output = process.outputStream()
  var errout = process.errorStream()

  while process.running:
    for err in errout.lines:
      taNWSyncOutput.addLine(err)
      taNWSyncOutput.forceRedraw()
      taNWSyncOutput.scrollToBottom()

    for line in output.lines:
      taNWSyncOutput.addLine(line)
      taNWSyncOutput.forceRedraw()
      taNWSyncOutput.scrollToBottom()

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
  * any valid other erf container (HAK, ERF) [NOT IMPLIMENTED]
  * single files, including a TLK file [NOT IMPLIMENTED]
  * a directory containing single files [NOT IMPLIMENTED]


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
  Force rewrite of existing data.

  Compression
  Compress repostory data. This saves disk space and speeds
  up transfers if your webserver does not speak gzip or
  deflate compression.

  Group-ID
  Set a group ID. Do this if you run multiple data sets
  from the same repository. Manifests with the same ID
  are considered for auto-removal by clients when
  superseded by a newer download. [default: 0]""")
