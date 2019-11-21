import os, osproc, streams, parsecfg, strutils
import nigui


var fileSource, folderDestination, modName, modDescription: string
var verbose, quiet, withmod, forcerewrite: bool
const gui_version: string = "0.2.0"

proc writeConfig()
proc readConfig()
proc onLoad()
proc nwsyncWrite()
proc chooseSource()
proc chooseDestination()
proc nwsyncWriteHelp()

app.init()


var window = newWindow("NWSync GUI v" & gui_version)
window.height = 700.scaleToDpi()
window.width = 600.scaleToDpi()
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
containerSourceDestination.height = 120

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
textboxModName.height = 25

var containerModDescription = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerModDescription)
containerModDescription.frame = newFrame("Module Description (blank = extracts from module source if possible)")
var textareaModDescription = newTextArea(modDescription)
textareaModDescription.height = 70
containerModDescription.add(textareaModDescription)


var containerCheckboxes = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerCheckboxes)
containerCheckboxes.height = 32

var checkboxVerbose = newCheckbox("Verbose Output")
checkboxVerbose.checked = verbose
containerCheckboxes.add(checkboxVerbose)
var checkboxQuiet = newCheckbox("Quite Output")
checkboxQuiet.checked = quiet
containerCheckboxes.add(checkboxQuiet)
var checkboxForceRewrite = newCheckbox("Force Rewrite")
checkboxForceRewrite.checked = forcerewrite
containerCheckboxes.add(checkboxForceRewrite)
var checkboxWithMod = newCheckbox("With Module")
checkboxWithMod.checked = withmod
containerCheckboxes.add(checkboxWithMod)

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

checkboxForceRewrite.onClick = proc(event:ClickEvent) =
  if checkboxForceRewrite.checked == false:
    forcerewrite = true
  else:
    forcerewrite = false

checkboxWithMod.onClick = proc(event:ClickEvent) =
  if checkboxWithMod.checked == false:
    withmod = true
    checkboxWithMod.checked = true
    window.alert("Check Help to ensure you intend to use this option")
  else:
    withmod = false


var taNWSyncOutput = newTextArea()
var containerOutput = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerOutput)
containerOutput.frame = newFrame("Output")

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
  cfg.setSectionKey("nwsync_write", "ForceRewrite", $forcerewrite)
  cfg.setSectionKey("nwsync_write", "WithMod", $withmod)
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
    forcerewrite = cfg.getSectionValue("nwsync_write", "ForceRewrite").parseBool
    withmod = cfg.getSectionValue("nwsync_write", "WithMod").parseBool
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
  if forcerewrite == true:
    result.add("-f")
  if withmod == true:
    result.add("--with-module")

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

  let process = startProcess("nwsync_write", getAppDir(), args, nil, {poUsePath, poDaemon})
  let output = process.outputStream()
  let errout = process.errorStream()

  while process.running:
    for err in errout.lines:
      if err != "":
        taNWSyncOutput.addLine(err)
        taNWSyncOutput.forceRedraw()
        taNWSyncOutput.scrollToBottom()

    for line in output.lines:
      if line != "":
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

  Compression
    Compress repostory data. This saves disk space and speeds
    up transfers if your webserver does not speak gzip or
    deflate compression.

  Group-ID
    Set a group ID. Do this if you run multiple data sets
    from the same repository. Manifests with the same ID
    are considered for auto-removal by clients when
    superseded by a newer download. [default: 0]""")
