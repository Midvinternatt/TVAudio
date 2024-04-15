#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
#Include JSON.ahk

TRAY_TITLE := "TV Audio"
TRAY_ICON := "trayicon.ico"
SETTINGS_FILEPATH := "settings.json"

InitScript()

InitScript() {
	Settings.Load()

	A_IconTip := TRAY_TITLE
	TraySetIcon(TRAY_ICON)

	A_TrayMenu.Delete()

	A_TrayMenu.Add("Start Kodi TV", MenuEvent.StartKodiTV.Bind(MenuEvent))
	A_TrayMenu.Add()

	for deviceTitle, deviceName in Settings.Devices {
		A_TrayMenu.Add("Reset to &" deviceTitle, MenuEvent.ResetToSoundDevice.Bind(MenuEvent))
	}
	A_TrayMenu.Add()
	
	A_TrayMenu.Add("Notification message", MenuEvent.Dummy.Bind(MenuEvent))
	if(Settings.MessageNotification)
		A_TrayMenu.Check("Notification message")
	
	A_TrayMenu.Add("Notification audio", MenuEvent.Dummy.Bind(MenuEvent))
	if(Settings.AudioNotification)
		A_TrayMenu.Check("Notification audio")

	A_TrayMenu.Add("Settings", MenuEvent.OpenSettings.Bind(MenuEvent))
	A_TrayMenu.Add("Exit", MenuEvent.Exit.Bind(MenuEvent))
}

class MenuEvent {
	static StartKodiTV(*) {
		if(Settings.MessageNotification)
			TrayTip("Starting Kodi TV", "TV Audio")

		if(SoundDevice.ResetTo(Settings.Device["TV"])) {
			Overlay.Show()
			Sleep(Settings.TVDelay)
			Run(Settings.KodiApplicationPath)
			Sleep(1000)
			Overlay.Hide()
		}
		else {
			if(Settings.MessageNotification)
				TrayTip("Failed to start Kodi TV", "TV Audio")
		}
	}

	static ResetToSoundDevice(ItemName, ItemPos, *) {
		global config

		deviceMenuName := SubStr(ItemName, 11)
		if(Settings.MessageNotification)
			TrayTip("Reseting to " deviceMenuName, "TV Audio")

		if(SoundDevice.ResetTo(Settings.Device[deviceMenuName])) {
			if(Settings.MessageNotification)
				TrayTip("Changed to " deviceMenuName, "TV Audio")
			if(Settings.AudioNotification)
				SoundPlay("*64")
		}
		else {
			if(Settings.MessageNotification)
				TrayTip("Failed change", "TV Audio")
			if(Settings.AudioNotification)
				SoundPlay("*64")
		}
	}

	static OpenSettings(*) {
		RunWait("notepad.exe " SETTINGS_FILEPATH,,, &processId)
		WinWaitClose("ahk_pid " processId)
		TrayTip("Updated settings", "TV Audio")
		Reload()
	}

	static Dummy(*) {
		MouseGetPos(&xPos, &yPos)
		A_TrayMenu.Show(xPos, yPos + 50)
	}

	static Exit(*) {
		ExitApp()
	}
}

class SoundDevice {
	static SetAsDefault(deviceName) {
		RunWait("nircmd.exe setdefaultsounddevice " deviceName)
		return SoundGetName()==deviceName
	}

	static ResetTo(deviceName) {
		if(SoundDevice.WaitUntilExists(Settings.Device["TV"])) {
			Sleep(1000)
			return SoundDevice.SetAsDefault(deviceName)
		}

		return false
	}

	static WaitUntilExists(deviceName, timeout:=300000) { ; 5 minues
		endTime := A_TickCount + timeout

		while(A_TickCount < endTime) {
			for Device in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_PnPEntity Where PNPClass='AudioEndpoint' Or PNPClass='Ljudslutpunkt'") {
				if(Device.name==deviceName)
					return true
			}

			Sleep(1000)
		}

		return false
	}
}

class Settings {
	static Load() {
		file := FileOpen(SETTINGS_FILEPATH, "r")
		data := file.Read()
		file.Close()
		Settings._data := JSON_Load(data)

		activeDevices := Map()
		for Device in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_PnPEntity Where PNPClass='AudioEndpoint' Or PNPClass='Ljudslutpunkt'") {
			activeDevices[Device.name] := true
		}

		newDeviceList := Settings._data["devices"].Clone()
		for deviceName, deviceId in Settings._data["devices"] {
			if(deviceName=="TV")
				continue
			if(not activeDevices.Has(deviceId))
				newDeviceList.Delete(deviceName)
		}
		Settings._data["devices"] := newDeviceList
	}

	static KodiApplicationPath {
		get {
			return Settings._data["kodiApplicationPath"]
		}
	}

	static TVDelay {
		get {
			return Settings._data["tvDelay"]
		}
	}

	static MessageNotification {
		get {
			return Settings._data["showNotification"]
		}
	}

	static AudioNotification {
		get {
			return Settings._data["playNotificationAudio"]
		}
	}

	static Devices {
		get {
			return Settings._data["devices"]
		}
	}

	static Device[deviceName] {
		get {
			return Settings._data["devices"][deviceName]
		}
	}
}

class Overlay {
	static Show() {
		Overlay._gui := Gui("+AlwaysOnTop -SysMenu -Theme -Caption")
		Overlay._gui.BackColor := "000000"
		Overlay.button := Overlay._gui.Add("Picture", "W" A_ScreenWidth " H" A_ScreenHeight " X0 Y0")
		Overlay.button.OnEvent("Click", Overlay.OnClick.Bind(Overlay))
		Overlay.text := Overlay._gui.Add("Text", "W" A_ScreenWidth " H" A_ScreenHeight " X0 Y450 Center", "Starting Kodi")
		Overlay.text.SetFont("s48 cWhite")
		Overlay._gui.Show("W" A_ScreenWidth " H" A_ScreenHeight " X0 Y0")
	}

	static Hide() {
		Overlay._gui.Hide()
	}
	
	static OnClick(*) {
		Overlay.Hide()
	}
}

if(not A_IsCompiled) {
	^r:: {
		Reload()
	}
}