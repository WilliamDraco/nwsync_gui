import os, osproc, streams, parsecfg, strutils
import nigui


var fileSource, folderDestination, modName, modDescription: string
var verbose, quiet, withmod, forcerewrite, nolatest, nocompression: bool
var groupid: int
const gui_version: string = "0.3.0"

proc writeConfig()
proc readConfig()
proc onLoad()
proc nwsyncWrite()
proc chooseSource()
proc chooseDestination()
proc nwsyncWriteHelp()

app.init()


let window = newWindow("NWSync GUI v" & gui_version)
window.height = 700.scaleToDpi()
window.width = 600.scaleToDpi()
window.onCloseClick = proc(event: CloseClickEvent) =
  writeConfig()
  window.dispose()

onLoad()

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

let buttonWrite = newButton("NWSync Write")
containerNWSyncButtons.add(buttonWrite)
buttonWrite.onClick = proc(event: ClickEvent) =
  nwsyncWrite()

let buttonPrint = newButton("Print-ComingSoon") #("NWSync Print")
containerNWSyncButtons.add(buttonPrint)

let buttonPrune = newButton("Prune-ComingSoon") #("NWSync Prune")
containerNWSyncButtons.add(buttonPrune)

let buttonHelp = newButton("Help")
containerHelpButton.add(buttonHelp)
buttonHelp.onClick = proc(event: ClickEvent) =
  nwsyncWriteHelp()

let containerSourceDestination = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerSourceDestination)
containerSourceDestination.widthMode = WidthMode_Expand
containerSourceDestination.height = 120

let containerSource = newLayoutContainer(Layout_Vertical)
containerSourceDestination.add(containerSource)

let textareaSource = newTextArea()
textareaSource.text = "Chosen file:\p" & fileSource
containerSource.add(textareaSource)
textareaSource.editable = false
textareaSource.wrap = true
textareaSource.height = 60
textareaSource.widthMode = WidthMode_Expand

let buttonChooseSource = newButton("Choose Source...")
containerSource.add(buttonChooseSource)
buttonChooseSource.onClick = proc(event: ClickEvent) =
  chooseSource()

let lableSourceLimit = newLabel("Currently only supports passing a single file")
containerSource.add(lableSourceLimit)

let containerDestination = newLayoutContainer(Layout_Vertical)
containerSourceDestination.add(containerDestination)

let textareaDestination = newTextArea()
containerDestination.add(textareaDestination)
textareaDestination.text = "NWSync Destination:\p" & folderDestination
textareaDestination.editable = false
textareaDestination.wrap = true
textareaDestination.height = 60
textareaDestination.widthMode = WidthMode_Expand

let buttonChooseDestination = newButton("Choose Destination...")
containerDestination.add(buttonChooseDestination)
buttonChooseDestination.onClick = proc(event: ClickEvent) =
  chooseDestination()

let containerModName = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerModName)
containerModName.frame = newFrame("Module Name (blank = extracts from module source if possible)")
let textboxModName = newTextBox(modName)
containerModName.add(textboxModName)
textboxModName.height = 25

let containerModDescription = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerModDescription)
containerModDescription.frame = newFrame("Module Description (blank = extracts from module source if possible)")
let textareaModDescription = newTextArea(modDescription)
textareaModDescription.height = 70
containerModDescription.add(textareaModDescription)


let containerAdditionalOptionsOne = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerAdditionalOptionsOne)
containerAdditionalOptionsOne.yAlign = YAlign_Center
containerAdditionalOptionsOne.height = 32

let containerAdditionalOptionsTwo = newLayoutContainer(Layout_Horizontal)
containerPrimary.add(containerAdditionalOptionsTwo)
containerAdditionalOptionsTwo.height = 32

let checkboxVerbose = newCheckbox("Verbose Output")
let checkboxQuiet = newCheckbox("Quite Output")
let lableGroupID = newLabel("Group ID: ")
let textboxGroupID = newTextBox($groupid)
let checkboxForceRewrite = newCheckbox("Force Rewrite")
let checkboxWithMod = newCheckbox("With Module")
let checkboxNoLatest = newCheckbox("No 'Latest' update")
let checkboxNoCompression = newCheckbox("Disable Compression")
checkboxVerbose.checked = verbose
checkboxQuiet.checked = quiet
textboxGroupID.width = 50
checkboxForceRewrite.checked = forcerewrite
checkboxWithMod.checked = withmod
checkboxNoLatest.checked = nolatest
checkboxNoCompression.checked = nocompression
containerAdditionalOptionsOne.add(checkboxVerbose)
containerAdditionalOptionsOne.add(checkboxQuiet)
containerAdditionalOptionsOne.add(lableGroupID)
containerAdditionalOptionsOne.add(textboxGroupID)
containerAdditionalOptionsTwo.add(checkboxForceRewrite)
containerAdditionalOptionsTwo.add(checkboxWithMod)
containerAdditionalOptionsTwo.add(checkboxNoLatest)
containerAdditionalOptionsTwo.add(checkboxNoCompression)


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

textboxGroupID.onTextChange = proc(event: TextChangeEvent) =
  if textboxGroupID.text == "":
    groupid = 0
    textboxGroupID.text = "0"
    return

  try:
    groupid = textboxGroupID.text.parseInt
    if groupid < 0:
      groupid = abs(groupid)
      textboxGroupID.text = $groupid
  except ValueError:
    window.alert("GroupID must be a positive integer")
    textboxGroupID.text = $groupid

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

checkboxNoLatest.onClick = proc(event:ClickEvent) =
  if checkboxNoLatest.checked == false:
    nolatest = true
  else:
    nolatest = false

checkboxNoCompression.onClick = proc(event:ClickEvent) =
  if checkboxNoCompression.checked == false:
    nocompression = true
  else:
    nocompression = false

let taNWSyncOutput = newTextArea()
let containerOutput = newLayoutContainer(Layout_Horizontal)
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
  cfg.setSectionKey("nwsync_write", "GroupID", $groupid)
  cfg.setSectionKey("nwsync_write", "ForceRewrite", $forcerewrite)
  cfg.setSectionKey("nwsync_write", "WithMod", $withmod)
  cfg.setSectionKey("nwsync_write", "NoLatest", $nolatest)
  cfg.setSectionKey("nwsync_write", "NoCompression", $nocompression)
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
    groupid = cfg.getSectionValue("nwsync_write", "GroupID").parseInt
    forcerewrite = cfg.getSectionValue("nwsync_write", "ForceRewrite").parseBool
    withmod = cfg.getSectionValue("nwsync_write", "WithMod").parseBool
    nolatest = cfg.getSectionValue("nwsync_write", "NoLatest").parseBool
    nocompression = cfg.getSectionValue("nwsync_write", "NoCompression").parseBool
    modName = cfg.getSectionValue("nwsync_write", "ModName")
    modDescription = cfg.getSectionValue("nwsync_write", "ModDescription").convertLineBreaks
  except:
    return

proc onLoad() =
  var process: Process
  try:
    process = startProcess("nwsync_write", getAppDir(), @["--version"], nil, {
        poUsePath, poDaemon})
  except OSError:
    window.alert("Error: Ensure nwsync_write is in PATH or same directory as nwsync_gui.\n\n" & getCurrentExceptionMsg())
    window.dispose()
    return

  let output = process.outputStream()
  window.title = "NWSync GUI v" & gui_version & " - nwsync version: " &
      output.readline()

  readConfig()

proc chooseSource() =
  let dialog = newOpenFileDialog()
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
  let dialog = newSelectDirectoryDialog()
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
  if withmod == true:
    result.add("--with-module")
  if nolatest == true:
    result.add("--no-latest")
  if textboxModName.text != "":
    result.add("--name=\"" & textboxModName.text & "\"")
  if textareaModDescription.text != "":
    result.add("--description=\"" & textareaModDescription.text & "\"")
  if forcerewrite == true:
    result.add("-f")
  if nocompression == true:
    result.add("--compression=none")
  if groupid != 0:
    result.add("--group-id=" & $groupid)

  result.add(folderDestination)
  result.add(fileSource) #in future will be a for-loop to include all sources

proc nwsyncWrite() =
  let args = constructArgs()

  if args == @[]:
    return

  taNWSyncOutput.addLine($args)

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

  Disable Compression
    By default, Compress repostory data. This saves disk space
    and speeds up transfers if your webserver does not speak
    gzip or deflate compression. Check to disable.

  Group-ID
    Set a group ID. Do this if you run multiple data sets
    from the same repository. Manifests with the same ID
    are considered for auto-removal by clients when
    superseded by a newer download. [default: 0]""")
