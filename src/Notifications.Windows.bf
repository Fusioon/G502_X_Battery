#if BF_PLATFORM_WINDOWS

using System;
using System.Interop;
using System.Collections;
using System.Threading;

namespace FuKeys;

class Notifications_Windows : Notifications
{
	const int NOTIFY_ID = WM_APP + 0xDDC;
	const int CMD_TOGGLE_CONSOLE = WM_USER + 10;
	const int CMD_EXIT = WM_USER + 11;
	const int WMU_COMMIT = WM_USER + 12;


	HIcon[Enum.GetCount<EIcon>()] _iconMap;

	[CallingConvention(.Stdcall), CLink]
	static extern HIcon CreateIconFromResourceEx(void* prebits, c_uint dwResSize, Windows.IntBool fIcon, c_uint dwVer, c_int cxDesired, c_int cyDesired, c_uint Flags);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.HWnd GetConsoleWindow();

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
		_nid = .();
		_nid.cbSize = sizeof(decltype(_nid));
		_nid.hWnd = _hWnd;
		_nid.uCallbackMessage = NOTIFY_ID;
		_nid.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP;
		// LoadImageW
		_nid.hIcon = _iconMap[0]; //LoadIconW(0, (.)(void*)(int)32515);
		//_nid.hIcon = (.)LoadImageW(0, "K:\\I2PTorrent\\icon.bmp".ToScopedNativeWChar!(), 0, 0, 0, 0x00000040);
		
		_nid.hBalloonIcon = _nid.hIcon;
		_nid.uVersion = 4;

		CopyWide(ref _nid.szTip, "Tip\n100%\nCharging");
		CopyWide(ref _nid.szInfo, "Info");
		CopyWide(ref _nid.szInfoTitle, "InfoTitle");
		
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