#SingleInstance Force
Persistent

#Include JSON.ahk

; https://www.nirsoft.net/utils/nircmd2.html#using
; https://www.nirsoft.net/utils/sound_volume_view.html#command_line
; https://www.reddit.com/r/AutoHotkey/comments/f38o95/muting_specific_application_with_nircmd/
; https://www.autohotkey.com/docs/v2/lib/SoundGetName.htm

TRAY_TITLE := "TV Audio"
TRAY_ICON := "trayicon.ico"
SETTINGS_FILEPATH := "settings.json"

InitScript()

InitScript() {
	Settings.Load()

	A_IconTip := TRAY_TITLE
	TraySetIcon(TRAY_ICON)

	A_TrayMenu.Delete()

	A_TrayMenu.Add("Start Kodi TV", MenuEvent.StartKodiTV)
	A_TrayMenu.Add()

	for deviceTitle, deviceName in Settings.Devices {
		A_TrayMenu.Add("Reset to &" deviceTitle, MenuEvent.ResetToSoundDevice.Bind(MenuEvent))
	}
	A_TrayMenu.Add()
	
	A_TrayMenu.Add("Notification message", MenuEvent.Dummy)
	if(Settings.MessageNotification)
		A_TrayMenu.Check("Notification message")
	
	A_TrayMenu.Add("Notification audio", MenuEvent.Dummy)
	if(Settings.AudioNotification)
		A_TrayMenu.Check("Notification audio")

	A_TrayMenu.Add("Settings", MenuEvent.OpenSettings)
	A_TrayMenu.Add("Exit", MenuEvent.Exit)
}


class MenuEvent {
	static StartKodiTV(ItemName, ItemPos, *) {
		if(Settings.MessageNotification)
			TrayTip("Starting Kodi TV", "TV Audio")

		if(SoundDevice.ResetTo(Settings.Device["TV"])) {
			Overlay.Show()
			Sleep(20000)
			Run(Settings.kodiApplicationPath)
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

	static OpenSettings(ItemName, ItemPos, *) {
		RunWait("notepad.exe " SETTINGS_FILEPATH,,, &processId)
		WinWaitClose("ahk_pid " processId)
		TrayTip("Updated settings", "TV Audio")
		Reload()
	}

	static Dummy(*) {
		MouseGetPos(&xPos, &yPos)
		A_TrayMenu.Show(xPos, yPos + 50)
	}

	static Exit(ItemName, ItemPos, *) {
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

			; Loop {
			; 	try
			; 		devName := SoundGetName(, dev := A_Index)
			; 	catch
			; 		break
				
			; 	if(devName==deviceName && MonitorGetCount() > 2)
			; 		return true
			; }
		}

		return false
	}
}

class Settings {
	static Load() {
		file := FileOpen(SETTINGS_FILEPATH, "r")
		data := file.Read()
		file.Close()
		Settings.instance := JSON_Load(data)
	}

	static kodiApplicationPath {
		get {
			return Settings.instance["kodiApplicationPath"]
		}
	}

	static Devices {
		get {
			return Settings.instance["devices"]
		}
	}

	static Device[deviceName] {
		get {
			return Settings.instance["devices"][deviceName]
		}
	}

	static MessageNotification {
		get {
			return Settings.instance["showNotification"]
		}
	}

	static AudioNotification {
		get {
			return Settings.instance["playNotificationAudio"]
		}
	}
}

class Overlay {
	static Show() {
		Overlay.instance := Gui("+AlwaysOnTop -SysMenu -Theme -Caption")
		Overlay.instance.BackColor := "000000"
		Overlay.button := Overlay.instance.Add("Picture", "W" A_ScreenWidth " H" A_ScreenHeight " X0 Y0")
		Overlay.button.OnEvent("Click", Overlay.OnClick.Bind(Overlay))
		Overlay.text := Overlay.instance.Add("Text", "W" A_ScreenWidth " H" A_ScreenHeight " X0 Y450 Center", "Starting Kodi")
		Overlay.text.SetFont("s48 cWhite")
		Overlay.instance.Show("W" A_ScreenWidth " H" A_ScreenHeight " X0 Y0")
	}
	static Hide() {
		Overlay.instance.Hide()
		Overlay.instance.Destroy()
	}
	static OnClick(*) {
		Overlay.Hide()
	}
}