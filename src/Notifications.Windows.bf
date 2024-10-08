#if BF_PLATFORM_WINDOWS

using System;
using System.Interop;
using System.Collections;
using System.Threading;
using System.Diagnostics;

namespace FuKeys;

class Notifications_Windows : Notifications
{
	const String APP_REGISTRY_NAME = "FuBattery";
	const String RUN_ON_STARTUP_REGISTRY_PATH = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";

	static char16[?] APP_REGISTRY_NAME_WIDE = APP_REGISTRY_NAME.ToConstNativeW();
	static char16[?] RUN_ON_STARTUP_REGISTRY_PATH_WIDE = RUN_ON_STARTUP_REGISTRY_PATH.ToConstNativeW();

	const int NOTIFY_ID = WM_APP + 0xDDC;
	const int CMD_TOGGLE_CONSOLE = WM_USER + 10;
	const int CMD_EXIT = WM_USER + 11;
	const int CMD_TOGGLE_STARTUP = WM_USER + 12;
	const int CMD_OPEN_LOGS = WM_USER + 13;
	const int WMU_COMMIT = WM_USER + 30;


	HIcon[Enum.GetCount<EIcon>()] _iconMap;

	Windows.HInstance _hApp;
	Windows.HWnd _hWnd;
	HMenu _hCtxMenu;
	NOTIFYICONDATAW _nid;
	append Monitor _syncMonitor;
	append WaitEvent _changeEvent;

	Windows.HWnd _consoleWindow = default;
	bool _consoleVisible;

	~this()
	{
		DestroyWindow(_hWnd);
		Shell_NotifyIconW(NIM_DELETE, &_nid);
	}

	public override Result<void> Init()
	{
		_hApp = (.)Windows.GetModuleHandleW(null);

		if (!CreateMainWindow())
			return .Err;

		if (!CreateIcons())
		{
			NOP!();
		}

		_consoleWindow = GetConsoleWindow();
		if (_consoleWindow != default)
		{
			_consoleVisible = true;
			PostMessageW(_hWnd, WM_COMMAND, CMD_TOGGLE_CONSOLE, 0);
		}

		if (!CreateNotifyIcon())
			return .Err;

		if (!CreateNotifyIconContextMenu())
			return .Err;

		return .Ok;
	}

	[CallingConvention(.Stdcall)]
	static c_longlong DefaultWndProc(Windows.HWnd hwnd, c_uint uMsg, uint wParam, int lParam)
	{
		let ptr = (void*)Windows.GetWindowLongPtrW((.)hwnd, GWLP_USERDATA);
		if (ptr != null)
		{
			let instance = (Self)Internal.UnsafeCastToObject(ptr);
			instance.WndProc(hwnd, uMsg, wParam, lParam);
		}

		return DefWindowProcW(hwnd, uMsg, wParam, lParam);
	}

	c_longlong WndProc(Windows.HWnd hwnd, c_uint uMsg, uint wParam, int lParam)
	{
		switch (uMsg)
		{
		case NOTIFY_ID:
			{
				if (lParam & 0xFFFF == WM_CONTEXTMENU)
				{
					POINT p = ?;
					if (GetCursorPos(&p))
					{
						SetForegroundWindow(_hWnd);
						TrackPopupMenu(_hCtxMenu, TPM_LEFTALIGN | TPM_TOPALIGN | TPM_RIGHTBUTTON | TPM_VERNEGANIMATION, p.x, p.y, 0, _hWnd, null);
					}
				}

				break;
			}

		case WM_COMMAND:
			{
				switch(wParam)
				{
				case CMD_TOGGLE_CONSOLE:
					{
						_consoleVisible = !_consoleVisible;

						ShowWindow(_consoleWindow, (int32)(_consoleVisible ? SW_SHOW : SW_HIDE));
						CheckMenuItem(_hCtxMenu, CMD_TOGGLE_CONSOLE, (.)(MF_BYCOMMAND | (_consoleVisible ? MF_CHECKED : MF_UNCHECKED)));

						return 0;
					}

				case CMD_TOGGLE_STARTUP:
					{
						uint32 flags = (uint32)(IsRunAtStartup(true) ? MF_UNCHECKED : MF_CHECKED);
						SetRunAtStartup(flags == MF_CHECKED);
						CheckMenuItem(_hCtxMenu, CMD_TOGGLE_STARTUP, (uint32)MF_BYCOMMAND | flags);
						return 0;
					}

				case CMD_OPEN_LOGS:
					{
						ProcessStartInfo psi = scope ProcessStartInfo();
						psi.SetFileName(Program.LogsPath);
						psi.UseShellExecute = true;
						psi.SetVerb("Open");

						var process = scope SpawnedProcess();
						process.Start(psi).IgnoreError();
					}

				case CMD_EXIT:
					PostQuitMessage(0);
					return 0;
				}
			}
		case WMU_COMMIT:
			{
				if (_changeEvent.WaitFor(0))
				{
					using (_syncMonitor.Enter())
					{
						if (!Shell_NotifyIconW(NIM_MODIFY, &_nid))
						{
							Log.Error(scope $"[Win32] Failed to modify notify icon! ({Windows.GetLastError()})");
							break;
						}

						_changeEvent.Reset();
					}
				}
				else
				{
					Log.Warning("[Win32] Commit executed without pending changes?");
				}

				//UpdateListeningStatus(wParam != 0);
			}

		default:
			return DefWindowProcW(hwnd, uMsg, wParam, lParam);
		}

		return 0;
	}

	bool CreateMainWindow()
	{
		let classNameWide = "LogitechBatteryStatus".ToScopedNativeWChar!();

		WNDCLASSEXW wcx = default;
		wcx.cbSize = sizeof(WNDCLASSEXW);
		wcx.cbClsExtra = 0;
		wcx.cbWndExtra = 0;
		wcx.lpszClassName = classNameWide;
		wcx.hInstance = _hApp;
		wcx.lpfnWndProc = => DefaultWndProc;
		wcx.hCursor = LoadCursorW(0, IDC_ARROW);
		wcx.style = CS_OWNDC;

		let classAtom = RegisterClassExW(&wcx);
		if (classAtom == 0)
		{
			let err = Windows.GetLastError();
			const int ERROR_CLASS_ALREADY_EXISTS = 1410;

			if (err != ERROR_CLASS_ALREADY_EXISTS)
			{
				Log.Error(scope $"[Win32] Failed to register window class. ({Windows.GetLastError()})");
				return false;
			}
		}

		_hWnd = CreateWindowExW(0, classNameWide, "Title".ToScopedNativeWChar!(), WS_SYSMENU, 0, 0, 0, 0, 0, null, _hApp, null);
		if (_hWnd == 0)
		{
			Log.Error(scope $"[Win32] Failed to create window. ({Windows.GetLastError()})");
			return false;
		}

		Windows.SetWindowLongPtrW((.)_hWnd, GWLP_USERDATA, (.)Internal.UnsafeCastToPtr(this));

		return true;
	}

	static void CopyWide<TString, TSize>(ref char16[TSize] buffer, TString text)
		where TSize : const int
		where TString : const String
	{
		let native = text.ToConstNativeW();
		let count = Math.Min(native.Count - 1, buffer.Count - 1);
		for (int i in 0..<count)
		{
			buffer[i] = native[i];
		}
		buffer[count] = '\0';
	}

	bool CreateNotifyIcon()
	{
		_nid = .{
			cbSize = sizeof(decltype(_nid)),
			hWnd = _hWnd,
			uCallbackMessage = NOTIFY_ID,
			uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP,
			hIcon = _iconMap[0],
			hBalloonIcon = _nid.hIcon,
			uVersion = 4,
		};

		CopyWide(ref _nid.szTip, "Waiting for data");
		
		if (!Shell_NotifyIconW(NIM_ADD, &_nid))
		{
			Log.Error(scope $"[Win32] Failed to create notify icon! ({Windows.GetLastError()})");
			return false;
		}

		Shell_NotifyIconW(NIM_SETVERSION, &_nid);

		return true;
	}

	public override Result<void> CommitChanges()
	{
		if (_changeEvent.WaitFor(0) == false) 
			return .Ok; // No changes

		PostMessageW(_hWnd, WMU_COMMIT, 0, 0);
		return .Ok;
	}

	public override void UpdateTip(StringView newTip)
	{
		using (_syncMonitor.Enter())
		{
			switch (System.Text.UTF16.Encode(newTip, &_nid.szTip, _nid.szTip.Count))
			{
			case .Ok(let val):

				if (newTip.Length < _nid.szTip.Count)
					_nid.szTip[newTip.Length] = '\0';

				_changeEvent.Set(true);
			case .Err(let err):
				{
					Log.Error(scope $"[Win32] Failed to modify notify icon! encode failed: {err}");
				}
			}
		}
	}

	public override void UpdateIcon(EIcon icon)
	{
		using (_syncMonitor.Enter())
		{
			_nid.hIcon = _iconMap[icon.Underlying];
			_changeEvent.Set(true);
		}
	}

	bool IsRunAtStartup(bool checkPath)
	{
		c_wchar[Windows.MAX_PATH] buffer = default;
		uint32 length = buffer.Count;

		if (RegGetValueW(HKEY_CURRENT_USER, &RUN_ON_STARTUP_REGISTRY_PATH_WIDE, &APP_REGISTRY_NAME_WIDE, RRF_RT_REG_SZ, null, &buffer, &length) == 0)
		{
			if (checkPath)
			{
				String path = scope .(Span<c_wchar>(&buffer, length));
				return System.IO.File.Exists(path);
			}

			return true;
		}

		return false;
	}

	bool SetRunAtStartup(bool enable)
	{
		if (!enable)
		{
			return RegDeleteKeyValueW(HKEY_CURRENT_USER, &RUN_ON_STARTUP_REGISTRY_PATH_WIDE, &APP_REGISTRY_NAME_WIDE) == 0;
		}

		HKey hKey = default;
		uint32 disposition = 0;
		var res = RegCreateKeyExW(HKEY_CURRENT_USER, &RUN_ON_STARTUP_REGISTRY_PATH_WIDE, 0, null, REG_OPTION_NON_VOLATILE, KEY_WRITE, null, &hKey, &disposition);
		if (res != 0)
		{
			Log.Error(scope $"[Win32] Failed to create/open registry path '{RUN_ON_STARTUP_REGISTRY_PATH}'. ({Windows.GetLastError()})");
			return false;
		}
		defer RegCloseKey(hKey);

		c_wchar[Windows.MAX_PATH] buffer = default;
		let length = GetModuleFileNameW(0, &buffer, buffer.Count);

		if (length == 0)
		{
			Log.Error(scope $"[Win32] Failed to retrieve executable path. ({Windows.GetLastError()})");
			return false;
		}

		if (RegSetKeyValueW(hKey, null, &APP_REGISTRY_NAME_WIDE, REG_SZ, &buffer, length * sizeof(c_wchar)) != 0)
		{
			Log.Error(scope $"[Win32] Failed to set value of registry key '{APP_REGISTRY_NAME_WIDE}'. ({Windows.GetLastError()})");
			return false;
		}

		return true;
	}

	bool CreateNotifyIconContextMenu()
	{
		_hCtxMenu = CreatePopupMenu();
		if (_hCtxMenu.IsInvalid)
		{
			Log.Error(scope $"[Win32] Failed to initialize notify icon context menu! ({Windows.GetLastError()})");
			return false;
		}

		if (_consoleWindow != default)
			AppendMenuW(_hCtxMenu, MF_UNCHECKED, CMD_TOGGLE_CONSOLE, "Toggle Console".ToScopedNativeWChar!());

		bool atStartup = IsRunAtStartup(true);
		AppendMenuW(_hCtxMenu, (uint32)(atStartup ? MF_CHECKED : MF_UNCHECKED), CMD_TOGGLE_STARTUP, "Start with windows".ToScopedNativeWChar!());

		AppendMenuW(_hCtxMenu, MF_STRING, CMD_OPEN_LOGS, "Open logs directory".ToScopedNativeWChar!());
		AppendMenuW(_hCtxMenu, MF_STRING, CMD_EXIT, "Exit".ToScopedNativeWChar!());
		return true;
	}

	bool CreateIcons()
	{
		void CreateAndAdd(EIcon icon, Span<uint8> data)
		{
			let handle = CreateIconFromResourceEx(data.Ptr, (.)data.Length, true, 0x00030000, 128, 128, 0);
			if (handle.IsInvalid)
			{
				let err = Windows.GetLastError();
				Log.Error(err);
				return;
			}
			_iconMap[icon.Underlying] = handle;
		}
		CreateAndAdd(.BatteryFull, ICON_BATTERY_FULL);
		CreateAndAdd(.Battery_3_4, ICON_BATTERY_3_4);
		CreateAndAdd(.Battery_1_2, ICON_BATTERY_1_2);
		CreateAndAdd(.Battery_1_4, ICON_BATTERY_1_4);
		CreateAndAdd(.BatteryEmpty, ICON_BATTERY_EMPTY);

		CreateAndAdd(.Charging, ICON_CHARGING);
		CreateAndAdd(.ChargingError, ICON_CHARGING_ERROR);
		return true;
	}

	public override void Run(delegate bool() update)
	{
		MSG msg = default;

		while (GetMessageW(&msg, 0, 0, 0))
		{
			TranslateMessage(&msg);
			DispatchMessageW(&msg);
			if (update() == false)
				PostQuitMessage(0);
		}
	}
}

#endif