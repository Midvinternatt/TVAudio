#SingleInstance Force
#Persistent

Menu, Tray, Icon, trayicon.ico
Menu, Tray, Tip, TV Audio
Menu, Tray, NoStandard

Menu, Tray, Add, Start Kodi TV, StartKodiTV
Menu, Tray, Add, Reset to TV, ResetToTV
Menu, Tray, Add, Reset to Speakers, ResetToSpeakers
Menu, Tray, Add, Reset to Headphones, ResetToHeadphones
Menu, Tray, Add, Reset to VAC IN, ResetToVac
Menu, Tray, Add
Menu, Tray, Add, Exit, MenuItemExit

tvDevice := " 32_LCD_TV (NVIDIA High Definition Audio)"
headphoneDevice := "Headphones (Arctis 7 Game)"
speakerDevice := "Speakers (Realtek High Definition Audio)"
vacDevice := "VAC IN (Virtual Audio Cable)"


ResetToSoundDevice(deviceName) {
	global tvDevice, speakerDevice

	iterationCount := 0
	while(iterationCount<300) {
		if(CheckForSoundDevice(tvDevice)) {
			Sleep, 1000
			SetDefaultSoundDevice(speakerDevice)
			Sleep, 18000
			SetDefaultSoundDevice(deviceName)
			break
		}

		iterationCount := iterationCount + 1
		Sleep, 1000
	}
}

CheckForSoundDevice(searchedDeviceName) {
	global Devices
	Devices := {}
	Found := false

	IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
	DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+3*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 0x1, "UPtrP", IMMDeviceCollection, "UInt")
	ObjRelease(IMMDeviceEnumerator)
	DllCall(NumGet(NumGet(IMMDeviceCollection+0)+3*A_PtrSize), "UPtr", IMMDeviceCollection, "UIntP", Count, "UInt")
	
	Loop % (Count)
	{
	    DllCall(NumGet(NumGet(IMMDeviceCollection+0)+4*A_PtrSize), "UPtr", IMMDeviceCollection, "UInt", A_Index-1, "UPtrP", IMMDevice, "UInt")
	    DllCall(NumGet(NumGet(IMMDevice+0)+5*A_PtrSize), "UPtr", IMMDevice, "UPtrP", pBuffer, "UInt")
	    DeviceID := StrGet(pBuffer, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "UPtr", pBuffer)
	    DllCall(NumGet(NumGet(IMMDevice+0)+4*A_PtrSize), "UPtr", IMMDevice, "UInt", 0x0, "UPtrP", IPropertyStore, "UInt")
	    ObjRelease(IMMDevice)
	    VarSetCapacity(PROPVARIANT, A_PtrSize == 4 ? 16 : 24)
	    VarSetCapacity(PROPERTYKEY, 20)
	    DllCall("Ole32.dll\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "UPtr", &PROPERTYKEY)
	    NumPut(14, &PROPERTYKEY + 16, "UInt")
	    DllCall(NumGet(NumGet(IPropertyStore+0)+5*A_PtrSize), "UPtr", IPropertyStore, "UPtr", &PROPERTYKEY, "UPtr", &PROPVARIANT, "UInt")
	    DeviceName := StrGet(NumGet(&PROPVARIANT + 8), "UTF-16")    ; LPWSTR PROPVARIANT.pwszVal
	    DllCall("Ole32.dll\CoTaskMemFree", "UPtr", NumGet(&PROPVARIANT + 8))    ; LPWSTR PROPVARIANT.pwszVal

	    ObjRelease(IPropertyStore)
		ObjRawSet(Devices, DeviceName, DeviceID)

		if(DeviceName==searchedDeviceName) {
			Found := true
		}
	}
	ObjRelease(IMMDeviceCollection)
	return Found
}

SetDefaultSoundDevice(deviceName2) {
	global Devices

	For DeviceName, DeviceID in Devices {
        If (DeviceName==deviceName2) {
			IPolicyConfig := ComObjCreate("{870af99c-171d-4f9e-af0d-e63df40c2bc9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
		    DllCall(NumGet(NumGet(IPolicyConfig+0)+13*A_PtrSize), "UPtr", IPolicyConfig, "UPtr", &DeviceID, "UInt", 0, "UInt")
		    ObjRelease(IPolicyConfig)
            return
        }
	}
}

return

StartRenamingFiles:

return

StopRenamingFiles:

return

StartKodiTV:
	TrayTip, TV Audio, %tvDevice%
	ResetToSoundDevice(tvDevice)

	Sleep, 1000
	Run, % "C:\Program Files\Kodi\kodi.exe"
return

ResetToTV:
	TrayTip, TV Audio, %tvDevice%
	ResetToSoundDevice(tvDevice)
return

ResetToSpeakers:
	TrayTip, TV Audio, %speakerDevice%
	ResetToSoundDevice(speakerDevice)
return

ResetToHeadphones:
	TrayTip, TV Audio, %headphoneDevice%
	ResetToSoundDevice(headphoneDevice)
return

ResetToVac:
	TrayTip, TV Audio, %vacDevice%
	ResetToSoundDevice(vacDevice)
return

MenuItemExit:
    ExitApp
return

; ^r::
; 	Reload
; return