import os, osproc, streams, times
import nigui
import lib

proc chooseManifest(opt:ptr options)
proc nwsyncPrint(opt: ptr options, outlog: TextArea)

proc generatePrintContainers*(containerPrimary: LayoutContainer, opt:ptr options) =
  let containerManifest = newLayoutContainer(Layout_Vertical)
  containerPrimary.add(containerManifest)
  containerManifest.widthMode = WidthMode_Expand
  containerManifest.height = 120

  let textareaSource = newTextArea()
  textareaSource.text = "Choose Manifest:\p" & opt.manifestSource
  containerManifest.add(textareaSource)
  textareaSource.editable = false
  textareaSource.wrap = true
  textareaSource.height = 60
  textareaSource.widthMode = WidthMode_Expand

  let buttonChooseSource = newButton("Choose Manifest...")
  containerManifest.add(buttonChooseSource)

  let lableSourceLimit = newLabel("Select a specific manifest. Pick the one without .json")
  containerManifest.add(lableSourceLimit)

  let containerRunButton = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerRunButton)
  containerRunButton.xAlign = XAlign_Spread
  let buttonRun = newButton("RUN NWSYNC PRINT")
  buttonRun.widthMode = WidthMode_Expand
  buttonRun.fontSize = 25
  buttonRun.fontBold = true
  containerRunButton.add(buttonRun)


  let containerAdditionalOptionsOne = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerAdditionalOptionsOne)
  containerAdditionalOptionsOne.yAlign = YAlign_Center
  containerAdditionalOptionsOne.height = 32

  let checkboxVerbose = newCheckbox("Verbose Output")
  let checkboxQuiet = newCheckbox("Quite Output")
  checkboxVerbose.checked = opt.verbose
  checkboxQuiet.checked = opt.quiet
  containerAdditionalOptionsOne.add(checkboxVerbose)
  containerAdditionalOptionsOne.add(checkboxQuiet)

  let containerOutput = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerOutput)
  containerOutput.frame = newFrame("Output")

  let taNWSyncOutput = newTextArea()
  containerOutput.add(taNWSyncOutput)
  taNWSyncOutput.editable = false
  taNWSyncOutput.wrap = true

  buttonChooseSource.onClick = proc(event: ClickEvent) =
    opt.chooseManifest()
    textareaSource.text = "Choose Manifest:\p" & opt.manifestSource

  buttonRun.onClick = proc(event: ClickEvent) =
    opt.nwsyncPrint(taNWSyncOutput)

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



proc chooseManifest(opt:ptr options) =
  let dialog = newOpenFileDialog()
  dialog.title = "Choose Manifest"
  dialog.multiple = false
  dialog.directory = opt.folderDestination
  dialog.run()

  if dialog.files.len == 0:
    return

  if splitFile(dialog.files[0]).ext != "":
    let errorWindow = newWindow()
    errorWindow.alert("Must select the manifest without any extension")
    errorWindow.dispose()
  else:
    opt.manifestSource = dialog.files[0]

proc constructPrintArgs(opt:ptr options): seq[string] =
  if opt.manifestSource == "":
    let errorWindow = newWindow()
    errorWindow.alert("Please select a manifest file")
    errorWindow.dispose()
    return

  if opt.verbose == true:
    result.add("-v")
  elif opt.quiet == true:
    result.add("-q")

  result.add(opt.manifestSource)

proc nwsyncPrint(opt: ptr options, outlog: TextArea) =
  let args = constructPrintArgs(opt)

  if args == @[]:
    return

  outlog.text = "Process started with args \n" & $args & "\n\n This should clear in a moment. If it does not, try running with logs enabled to determine the error"

  var logFile = openFileStream(opt.manifestSource & ".txt", fmWrite)
  logFile.writeLine($args)

  let process = startProcess("nwsync_print", getAppDir(), args, nil, {poUsePath, poDaemon})
  let output = process.outputStream()
  let errout = process.errorStream()

  while process.running:
    var time1 = getTime()
    var time2: Time
    let timeDiff = initDuration(milliseconds = 500)

    for err in errout.lines:
      time2 = getTime()
      if err != "":
        logFile.writeLine(err)
        if time2 - time1 > timeDiff:
          outlog.text = err
          outlog.forceRedraw()
          outlog.scrollToBottom()
          app.processEvents()
          time1 = time2

  outlog.text = ""
  for line in output.lines:
    if line != "":
      logFile.writeLine(line)
      outlog.addLine(line)
  outlog.forceRedraw()
  outlog.scrollToBottom()
  app.processEvents()

  logFile.close()
