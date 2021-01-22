import os, osproc, streams, strutils, times
import nigui
import gui_lib

proc chooseSource(opt: Options)
proc chooseDestination(opt: Options)
proc nwsyncWrite(opt:  Options, outlog: TextArea)

proc generateWriteContainers*(containerPrimary: LayoutContainer, opt: Options) =
  let containerSourceDestination = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerSourceDestination)
  containerSourceDestination.widthMode = WidthMode_Expand
  containerSourceDestination.height = 120

  let containerSource = newLayoutContainer(Layout_Vertical)
  containerSourceDestination.add(containerSource)

  let textareaSource = newTextArea()
  textareaSource.text = "Chosen file:\p" & opt.fileSource
  containerSource.add(textareaSource)
  textareaSource.editable = false
  textareaSource.wrap = true
  textareaSource.height = 60
  textareaSource.widthMode = WidthMode_Expand

  let buttonChooseSource = newButton("Choose Source...")
  containerSource.add(buttonChooseSource)

  let lableSourceLimit = newLabel("Currently only supports passing a single file")
  containerSource.add(lableSourceLimit)

  let containerDestination = newLayoutContainer(Layout_Vertical)
  containerSourceDestination.add(containerDestination)

  let textareaDestination = newTextArea()
  containerDestination.add(textareaDestination)
  textareaDestination.text = "NWSync Destination:\p" & opt.folderDestination
  textareaDestination.editable = false
  textareaDestination.wrap = true
  textareaDestination.height = 60
  textareaDestination.widthMode = WidthMode_Expand

  let buttonChooseDestination = newButton("Choose Destination...")
  containerDestination.add(buttonChooseDestination)

  let containerRunButton = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerRunButton)
  containerRunButton.xAlign = XAlign_Spread
  let buttonRun = newButton("RUN NWSYNC WRITE")
  buttonRun.widthMode = WidthMode_Expand
  buttonRun.fontSize = 25
  buttonRun.fontBold = true
  containerRunButton.add(buttonRun)

  let containerModName = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerModName)
  containerModName.frame = newFrame("Module Name (blank = extracts from module source if possible)")
  let textboxModName = newTextBox(opt.modName)
  containerModName.add(textboxModName)
  textboxModName.height = 25


  let containerModDescription = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerModDescription)
  containerModDescription.frame = newFrame("Module Description (blank = extracts from module source if possible)")
  let textareaModDescription = newTextArea(opt.modDescription)
  textareaModDescription.height = 70
  containerModDescription.add(textareaModDescription)

  let containerAdditionalOptionsOne = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerAdditionalOptionsOne)
  containerAdditionalOptionsOne.yAlign = YAlign_Center
  containerAdditionalOptionsOne.height = 32

  let containerAdditionalOptionsTwo = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerAdditionalOptionsTwo)
  containerAdditionalOptionsTwo.yAlign = YAlign_Center
  containerAdditionalOptionsTwo.height = 32

  let checkboxVerbose = newCheckbox("Verbose Output")
  let checkboxQuiet = newCheckbox("Quite Output")
  #let comboboxOutput = newComboBox @["Quiet", "-", "Verbose"] Awaiting new nigui version post 0.2.4
  let lableGroupID = newLabel("Group ID:")
  let textboxGroupID = newTextBox($opt.groupid)
  let checkboxWriteLogs = newCheckbox("Write Logs")
  let checkboxWriteOrigin = newCheckbox("Write Origin")
  let checkboxForceRewrite = newCheckbox("Force Rewrite")
  let checkboxWithMod = newCheckbox("With Module")
  let lableFileSize = newLabel("Filesize limit:")
  let textboxFileSize = newTextBox($opt.filesizelimit)
  let checkboxNoLatest = newCheckbox("No 'Latest' update")
  let checkboxNoCompression = newCheckbox("No Compression")

  checkboxVerbose.checked = opt.verbose
  checkboxQuiet.checked = opt.quiet
  #comboboxOutput.index = opt.outputlvl Awaiting new nigui version post 0.2.4
  textboxGroupID.width = 40
  checkboxWriteLogs.checked = opt.writelogs
  checkboxWriteOrigin.checked = opt.writeorigin
  checkboxForceRewrite.checked = opt.forcerewrite
  checkboxWithMod.checked = opt.withmod
  textboxFileSize.width = 30
  checkboxNoLatest.checked = opt.nolatest
  checkboxNoCompression.checked = opt.nocompression
  containerAdditionalOptionsOne.add(checkboxVerbose)
  containerAdditionalOptionsOne.add(checkboxQuiet)
  #containerAdditionalOptionsOne.add(comboboxOutput) Awaiting new nigui version post 0.2.4
  containerAdditionalOptionsOne.add(lableGroupID)
  containerAdditionalOptionsOne.add(textboxGroupID)
  containerAdditionalOptionsOne.add(checkboxWriteLogs)
  containerAdditionalOptionsOne.add(checkboxWriteOrigin)
  containerAdditionalOptionsTwo.add(checkboxForceRewrite)
  containerAdditionalOptionsTwo.add(checkboxWithMod)
  containerAdditionalOptionsTwo.add(lableFileSize)
  containerAdditionalOptionsTwo.add(textboxFileSize)
  containerAdditionalOptionsTwo.add(checkboxNoLatest)
  containerAdditionalOptionsTwo.add(checkboxNoCompression)

  let taNWSyncOutput = newTextArea()
  let containerOutput = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerOutput)
  containerOutput.frame = newFrame("Output")

  containerOutput.add(taNWSyncOutput)
  taNWSyncOutput.editable = false
  taNWSyncOutput.wrap = true

  buttonChooseSource.onClick = proc(event: ClickEvent) =
    opt.chooseSource()
    textareaSource.text = "Chosen file:\p" & opt.fileSource

  buttonChooseDestination.onClick = proc(event: ClickEvent) =
    opt.chooseDestination()
    textareaDestination.text = "NWSync Destination:\p" & opt.folderDestination

  buttonRun.onClick = proc(event: ClickEvent) =
    opt.nwsyncWrite(taNWSyncOutput)

  textboxModName.onTextChange = proc(event: TextChangeEvent) =
    opt.modName = textboxModName.text

  textareaModDescription.onTextChange = proc(event: TextChangeEvent) =
    opt.modDescription = textareaModDescription.text

  checkboxVerbose.onClick = proc(event: ClickEvent) =
    if checkboxVerbose.checked == false:
      opt.verbose = true
      if checkboxQuiet.checked == true:
        checkboxQuiet.checked = false
        opt.quiet = false
    else:
      opt.verbose = false

  checkboxQuiet.onClick = proc(event: ClickEvent) =
    if checkboxQuiet.checked == false:
      opt.quiet = true
      if checkboxVerbose.checked == true:
        checkboxVerbose.checked = false
        opt.verbose = false
    else:
      opt.quiet = false

  checkboxWriteLogs.onClick = proc(event:ClickEvent) =
    if checkboxWriteLogs.checked == false:
      opt.writelogs = true
    else:
      opt.writelogs = false

  checkboxWriteOrigin.onClick = proc(event:ClickEvent) =
    if checkboxWriteOrigin.checked == false:
      opt.writeorigin = true
    else:
      opt.writeorigin = false

  textboxGroupID.onTextChange = proc(event: TextChangeEvent) =
    if textboxGroupID.text == "":
      opt.groupid = 0
      textboxGroupID.text = "0"
      return
    try:
      opt.groupid = textboxGroupID.text.parseInt
      if opt.groupid < 0:
        opt.groupid = abs(opt.groupid)
        textboxGroupID.text = $opt.groupid
    except ValueError:
      textboxGroupID.text = $opt.groupid

  checkboxForceRewrite.onClick = proc(event:ClickEvent) =
    if checkboxForceRewrite.checked == false:
      opt.forcerewrite = true
    else:
      opt.forcerewrite = false

  checkboxWithMod.onClick = proc(event:ClickEvent) =
    if checkboxWithMod.checked == false:
      opt.withmod = true
      checkboxWithMod.checked = true
      let errorWindow = newWindow()
      errorWindow.alert("Check Help to ensure you intend to use this option")
      errorWindow.dispose()
    else:
      opt.withmod = false

  textboxFileSize.onTextChange = proc(event: TextChangeEvent) =
    if textboxFileSize.text == "":
      opt.filesizelimit = 15
      textboxFileSize.text = "15"
      return
    try:
      opt.filesizelimit = textboxFileSize.text.parseInt
      if opt.filesizelimit < 1:
        opt.filesizelimit = 15
        textboxFileSize.text = "15"
    except ValueError:
      textboxFileSize.text = $opt.filesizelimit
    if opt.filesizelimit > 15:
      let warnWindow = newWindow()
      warnWindow.alert("Warning: Files above 15mb in size are rejected on-download by game clients")
      warnWindow.dispose()

  checkboxNoLatest.onClick = proc(event:ClickEvent) =
    if checkboxNoLatest.checked == false:
      opt.nolatest = true
    else:
      opt.nolatest = false

  checkboxNoCompression.onClick = proc(event:ClickEvent) =
    if checkboxNoCompression.checked == false:
      opt.nocompression = true
    else:
      opt.nocompression = false


proc chooseSource(opt: Options) =
  let dialog = newOpenFileDialog()
  dialog.title = "Choose Source"
  dialog.multiple = false
  dialog.directory = getHomeDir() / "documents/neverwinter nights/modules"
  dialog.run()

  if dialog.files.len == 0:
    return

  opt.filesource = dialog.files[0]

proc chooseDestination(opt: Options) =
  let dialog = newSelectDirectoryDialog()
  dialog.title = "Choose Destination"
  dialog.startDirectory = getAppDir()
  dialog.run()

  if dialog.selectedDirectory == "":
    return

  opt.folderDestination = dialog.selectedDirectory

proc constructArgs(opt: Options): seq[string] =
  let errorWindow = newWindow()
  if opt.folderDestination == "":
    errorWindow.alert("Please select a destination folder")
    return
  elif opt.fileSource == "":
    errorWindow.alert("Please select at least one Source File")
    return
  errorWindow.dispose()

  if opt.verbose == true:
    result.add("-v")
  elif opt.quiet == true:
    result.add("-q")
  if opt.withmod == true:
    result.add("--with-module")
  if opt.nolatest == true:
    result.add("--no-latest")
  if opt.modName != "":
    result.add("--name=\"" & opt.modName & "\"")
  if opt.modDescription != "":
    result.add("--description=\"" & opt.modName & "\"")
  if opt.forcerewrite == true:
    result.add("-f")
  if opt.nocompression == true:
    result.add("--compression=none")
  if opt.groupid != 0:
    result.add("--group-id=" & $opt.groupid)
  if opt.filesizelimit < 15 and opt.filesizelimit > 0:
    result.add("--limit-file-size=" & $opt.filesizelimit)
  if opt.writeorigin == true:
    result.add("--write-origins")

  result.add(opt.folderDestination)
  result.add(opt.fileSource) #in future will be a for-loop to include all sources

proc nwsyncWrite(opt: Options, outlog: TextArea) =
  let args = opt.constructArgs()

  if args == @[]:
    return

  outlog.text = "Process started with args \n" & $args & "\n\n This should clear in a moment. If it does not, try running with logs enabled to determine the error"

  var logFile: FileStream
  if opt.writelogs == true:
    createDir(opt.folderDestination)
    logFile = openFileStream(opt.folderDestination / format(now(),"yyMMdd-HHmmss") & "_write.txt", fmWrite)
    logFile.writeLine($args)

  let process = startProcess(findExe("nwsync_write"), getAppDir(), args, nil, {poUsePath, poDaemon})
  let output = process.outputStream()
  let errout = process.errorStream()

  var warnings: seq[string]

  while process.running:
    var time1 = getTime()
    var time2: Time
    let timeDiff = initDuration(milliseconds = 500)

    for err in errout.lines:
      time2 = getTime()
      if err != "":
        if opt.writelogs == true:
          logFile.writeLine(err)
        if time2 - time1 > timeDiff:
          outlog.text = err
          outlog.forceRedraw()
          outlog.scrollToBottom()
          app.processEvents()
          time1 = time2
        if err.startsWith('E') or err.startsWith('F') or err.startsWith("Error:") or err.startsWith("Fatal:"):
          let errorWindow = newWindow("")
          errorWindow.alert("NWSync has encountered a critical error!\n " & err & "\n\nIf this error is unclear, consider running with Logs to make seeking assistance easier.", "NWSync Error")
          process.terminate()
          if opt.writelogs == true:
            logFile.close()
          return
        if err.startsWith('W'):
          warnings.add(err)

  outlog.text = ""
  for line in output.lines:
    if line != "":
      if opt.writelogs == true:
        logFile.writeLine(line)
      outlog.addLine(line)

  if warnings.len != 0:
    outlog.addLine("\n Warnings were generated during the process and are repeated here")
    for warn in warnings:
      outlog.addLine(warn)

  outlog.forceRedraw()
  outlog.scrollToBottom()
  app.processEvents()

  if opt.writelogs == true:
    logFile.close()
