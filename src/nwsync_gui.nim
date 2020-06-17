import nigui
import gui_write, gui_print, gui_prune, gui_help, lib

app.init()

############### Window Definition
let window = newWindow("NWSync GUI v" & gui_version)
window.height = 700.scaleToDpi()
window.width = 600.scaleToDpi()

var opt = window.onLoad()

window.onCloseClick = proc(event: CloseClickEvent) =
  writeConfig(opt)
  window.dispose()
  app.quit()

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
generateWriteContainers(containerWrite, opt.addr)

let containerPrint = newLayoutContainer(Layout_Vertical)
containerPrimary.add(containerPrint)
containerPrint.hide()
generatePrintContainers(containerPrint, opt.addr)

let containerPrune = newLayoutContainer(Layout_Vertical)
containerPrimary.add(containerPrune)
containerPrune.hide()
generatePruneContainers(containerPrune, opt.addr)

let buttonWrite = newButton("NWSync Write")
containerNWSyncButtons.add(buttonWrite)
buttonWrite.onClick = proc(event:ClickEvent) =
  containerPrint.hide()
  containerPrune.hide()
  containerWrite.show()

let buttonPrune = newButton("NWSync Prune")
containerNWSyncButtons.add(buttonPrune)
buttonPrune.onClick = proc(event:ClickEvent) =
  containerPrint.hide()
  containerWrite.hide()
  containerPrune.show()

let buttonPrint = newButton("NWSync Print")
containerNWSyncButtons.add(buttonPrint)
buttonPrint.onClick = proc(event:ClickEvent) =
  containerPrune.hide()
  containerWrite.hide()
  containerPrint.show()

let buttonHelp = newButton("Help")
containerHelpButton.add(buttonHelp)
buttonHelp.onClick = proc(event: ClickEvent) =
  nwsyncHelp()

window.show()
app.run()


##########################################################################################
