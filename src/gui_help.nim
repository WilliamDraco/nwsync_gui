import nigui
import lib

proc nwsyncHelp*() =
  let windowHelp = newWindow("Help Window")
  windowHelp.height = 500.scaleToDpi()
  windowHelp.width = 500.scaleToDpi()
  windowHelp.show()

  windowHelp.onCloseClick = proc(event: CloseClickEvent) =
    windowHelp.dispose()

  let containerPrimary = newLayoutContainer(Layout_Vertical)
  windowHelp.add(containerPrimary)

  let containerHelpOptions = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerHelpOptions)

  let buttonWrite = newButton("Write Help")
  containerHelpOptions.add(buttonWrite)
  let buttonPrune = newButton("Prune Help")
  containerHelpOptions.add(buttonPrune)
  let buttonPrint = newButton("Print Help")
  containerHelpOptions.add(buttonPrint)

  let containerHelpTextArea = newLayoutContainer(Layout_Horizontal)
  containerPrimary.add(containerHelpTextArea)

  let textAreaHelpOutput = newTextArea(writeHelp)
  containerHelpTextArea.add(textAreaHelpOutput)
  textAreaHelpOutput.editable = false
  textAreaHelpOutput.wrap = true


  buttonWrite.onClick = proc(event:ClickEvent) =
    textAreaHelpOutput.text = writeHelp

  buttonPrune.onClick = proc(event:ClickEvent) =
    textAreaHelpOutput.text = pruneHelp

  buttonPrint.onClick = proc(event:ClickEvent) =
    textAreaHelpOutput.text = printHelp
