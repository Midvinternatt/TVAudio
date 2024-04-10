#SingleInstance Force
Persistent

#Include "JSON.ahk"

program := TVAudio()

class TVAudio {
	static TRAY_TITLE := "TV Audio"
	static TRAY_ICON := "trayicon.ico"
	static CONFIG_FILEPATH := "config.json"

	__New() {
		; Load config file
		file := FileOpen(TVAudio.CONFIG_FILEPATH, "r")
		fileData := file.Read()
		file.Close()
		this.config := JSON_Load(fileData)

		; Setup tray icon
		A_IconTip := TVAudio.TRAY_TITLE
		TraySetIcon(TVAudio.TRAY_ICON)

		; Setup tray menu
		A_TrayMenu.Delete()

		for deviceTitle, deviceName in this.config["devices"] {
			A_TrayMenu.Add(deviceTitle, this.Exit)
		}
		
		A_TrayMenu.Add()
		A_TrayMenu.Add("Exit", this.Exit)
	}

	InitTrayMenu() {

	}
	
	Exit(ItemPos, *) {
		MsgBox("Exit program")
		ExitApp()
	}
}

^r:: {
	Reload()
}