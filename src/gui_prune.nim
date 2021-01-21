import os, osproc, streams, times, strutils
import nigui
import gui_lib

proc chooseDestination(opt: Options)
proc nwsyncPrune(opt: Options, outlog: TextArea)

proc generatePruneContainers*(containerPrimary: LayoutContainer, opt: Options) =
  let containerDestination = newLayoutContainer(Layout_Vertical)
  containerPrimary.add(containerDestination)
  containerDestination.widthMode = WidthMode_Expand
  containerDestination.height = 120

  let textareaDestination = newTextArea()
  textareaDestination.text = "NWSync Repository:\p" & opt.folderDestination
  containerDestination.add(textareaDestination)
  textareaDestination.editable = false
  textareaDestination.wrap = true
  textareaDestination.height = 60
  textareaDestination.widthMode = WidthMode_Expand

  let buttonChooseDestination = newButton("Choose Repository...")
  containerDestination.add(buttonChooseDestination)

  let lableDestination = newLabel("Select folder containing your NWSync manifest")
  containerDestination.add(lableDestination)

  let containerRunButton = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerRunButton)
  containerRunButton.xAlign = XAlign_Spread
  let buttonRun = newButton("RUN NWSYNC PRUNE")
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
  let checkboxDryRun = newCheckbox("Simulate/Dry Run")
  let checkboxWriteLogs = newCheckbox("Write Logs to Repository")
  checkboxVerbose.checked = opt.verbose
  checkboxQuiet.checked = opt.quiet
  checkboxDryRun.checked = opt.dryrun
  checkboxWriteLogs.checked = opt.writelogs
  containerAdditionalOptionsOne.add(checkboxVerbose)
  containerAdditionalOptionsOne.add(checkboxQuiet)
  containerAdditionalOptionsOne.add(checkboxDryRun)
  containerAdditionalOptionsOne.add(checkboxWriteLogs)

  let containerOutput = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerOutput)
  containerOutput.frame = newFrame("Output")

  let taNWSyncOutput = newTextArea()
  containerOutput.add(taNWSyncOutput)
  taNWSyncOutput.editable = false
  taNWSyncOutput.wrap = true

  buttonChooseDestination.onClick = proc(event: ClickEvent) =
    opt.chooseDestination()
    textareaDestination.text = "NWSync Repository:\p" & opt.folderDestination

  buttonRun.onClick = proc(event: ClickEvent) =
    opt.nwsyncPrune(taNWSyncOutput)

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

  checkboxDryRun.onClick = proc(event:ClickEvent) =
    if checkboxDryRun.checked == false:
      opt.dryrun = true
    else:
      opt.dryrun = false

  checkboxWriteLogs.onClick = proc(event:ClickEvent) =
    if checkboxWriteLogs.checked == false:
      opt.writelogs = true
    else:
      opt.writelogs = false


proc chooseDestination(opt: Options) =
  let dialog = newSelectDirectoryDialog()
  dialog.title = "Choose Repository"
  dialog.startDirectory = getAppDir()
  dialog.run()

  if dialog.selectedDirectory == "":
    return

  opt.folderDestination = dialog.selectedDirectory

proc constructPruneArgs(opt: Options): seq[string] =
  if opt.folderDestination == "":
    let errorWindow = newWindow()
    errorWindow.alert("Please select a Repository folder")
    errorWindow.dispose()
    return

  if opt.verbose == true:
    result.add("-v")
  elif opt.quiet == true:
    result.add("-q")
  if opt.dryrun == true:
    result.add("-n")

  result.add(opt.folderDestination)

proc nwsyncPrune(opt: Options, outlog: TextArea) =
  let args = opt.constructPruneArgs()

  if args == @[]:
    return

  outlog.text = "Process started with args \n" & $args & "\n\n This should clear in a moment. If it does not, try running with logs enabled to determine the error"

  var logFile: FileStream
  if opt.writelogs == true:
    logFile = openFileStream(opt.folderDestination / format(now(),"yyMMdd-HHmmss") & "_prune.txt", fmWrite)
    logFile.writeLine($args)

  let process = startProcess(findExe("nwsync_prune"), getAppDir(), args, nil, {poUsePath, poDaemon})
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
          process.terminate
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
