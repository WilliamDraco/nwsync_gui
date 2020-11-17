import os, osproc, streams, times, strutils
import nigui
import gui_lib

proc chooseManifest(opt: Options)
proc nwsyncPrint(opt: Options, outlog: TextArea)

proc generatePrintContainers*(containerPrimary: LayoutContainer, opt: Options) =
  let containerManifest = newLayoutContainer(Layout_Vertical)
  containerPrimary.add(containerManifest)
  containerManifest.widthMode = WidthMode_Expand
  containerManifest.height = 120

  let textareaManifest = newTextArea()
  textareaManifest.text = "Choose Manifest:\p" & opt.manifestSource
  containerManifest.add(textareaManifest)
  textareaManifest.editable = false
  textareaManifest.wrap = true
  textareaManifest.height = 60
  textareaManifest.widthMode = WidthMode_Expand

  let buttonChooseSource = newButton("Choose Manifest...")
  containerManifest.add(buttonChooseSource)

  let lableManifest = newLabel("Select a specific manifest. Pick the one without .json")
  containerManifest.add(lableManifest)

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
    textareaManifest.text = "Choose Manifest:\p" & opt.manifestSource

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



proc chooseManifest(opt: Options) =
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

proc constructPrintArgs(opt: Options): seq[string] =
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

proc nwsyncPrint(opt: Options, outlog: TextArea) =
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
        if err.startsWith('E') or err.startsWith('F') or err.startsWith("Error:") or err.startsWith("Fatal:"):
          let errorWindow = newWindow("")
          errorWindow.alert("NWSync has encountered a critical error!\n " & err, "NWSync Error")
          process.terminate

  outlog.text = ""
  for line in output.lines:
    if line != "":
      logFile.writeLine(line)
      outlog.addLine(line)
  outlog.addLine("The print has completed. Please see the txt file created at the manifest's location")
  outlog.forceRedraw()
  outlog.scrollToBottom()
  app.processEvents()

  logFile.close()
