#if BF_PLATFORM_WINDOWS

using System;
using System.Interop;

namespace FuKeys;

static
{
	[CallingConvention(.Stdcall)]
	public function c_longlong WNDPROC(Windows.HWnd hwnd, c_uint uMsg, uint wParam, int lParam);

	public struct HMonitor : Windows.Handle { }
	public struct HIcon : Windows.Handle { }
	public struct HCursor : Windows.Handle { }
	public struct HMenu : Windows.Handle { }
	public struct HBrush : Windows.Handle { }
	public struct HDC : Windows.Handle { }
	public struct HGLRC : Windows.Handle { }

	[CRepr]
	public struct WNDCLASSEXW
	{
		public c_uint      cbSize;
		public c_uint      style;
		public WNDPROC   lpfnWndProc;
		public c_int       cbClsExtra;
		public c_int       cbWndExtra;
		public Windows.HInstance hInstance;
		public HIcon     hIcon;
		public HCursor   hCursor;
		public HBrush    hbrBackground;
		public char16*    lpszMenuName;
		public char16*    lpszClassName;
		public HIcon     hIconSm;
	}

	[CRepr]
	public struct POINT
	{
		public c_long x, y;
	}

	[CRepr]
	public struct MSG
	{
		public Windows.HWnd   hwnd;
		public c_uint message;
		public uint wParam;
		public int lParam;
		public c_uint time;
		public POINT pt;
		public c_uint lPrivate;
	}

	[CRepr]
	public struct FLASHWINFO
	{
		public c_uint cbSize;
		public Windows.HWnd  hwnd;
		public c_ulong dwFlags;
		public c_uint uCount;
		public c_ulong dwTimeout;
	}

	[CRepr]
	public struct PIXELFORMATDESCRIPTOR
	{
		public c_ushort nSize;
		public c_ushort nVersion;
		public c_ulong dwFlags;
		public c_uchar iPixelType;
		public c_uchar cColorBits;
		public c_uchar cRedBits;
		public c_uchar cRedShift;
		public c_uchar cGreenBits;
		public c_uchar cGreenShift;
		public c_uchar cBlueBits;
		public c_uchar cBlueShift;
		public c_uchar cAlphaBits;
		public c_uchar cAlphaShift;
		public c_uchar cAccumBits;
		public c_uchar cAccumRedBits;
		public c_uchar cAccumGreenBits;
		public c_uchar cAccumBlueBits;
		public c_uchar cAccumAlphaBits;
		public c_uchar cDepthBits;
		public c_uchar cStencilBits;
		public c_uchar cAuxBuffers;
		public c_uchar iLayerType;
		public c_uchar bReserved;
		public c_ulong dwLayerMask;
		public c_ulong dwVisibleMask;
		public c_ulong dwDamageMask;
	}

	[CRepr]
	public struct RECT : this(c_long left, c_long top, c_long right, c_long bottom)
	{
	}

	[CRepr]
	public struct TRACKMOUSEEVENT
	{
		public c_ulong cbSize;
		public c_ulong dwFlags;
		public Windows.HWnd  hwndTrack;
		public c_ulong dwHoverTime;
	}

	[CRepr]
	public struct MONITORINFO
	{
		public c_ulong cbSize;
		public RECT    rcMonitor;
		public RECT    rcWork;
		public c_ulong   dwFlags;
	}

	[CRepr]
	public struct MONITORINFOEXW : MONITORINFO
	{
		public char16[32] szDevice;
	}

	[CRepr]
	public struct RAWINPUTHEADER
	{
		public c_ulong dwType;
		public c_ulong dwSize;
		public Windows.Handle hDevice;
		public uint wParam;
	}

	[CRepr]
	public struct RAWINPUTDEVICE
	{
		public c_ushort usUsagePage;
		public c_ushort usUsage;
		public c_ulong dwFlags;
		public Windows.HWnd hwndTarget;
	}

	[CRepr]
	public struct RAWMOUSE
	{
		[CRepr, Union]
		struct DUMMYUNIONNAME
		{
			[CRepr]
			struct DUMMYSTRUCTNAME
			{
				public c_short usButtonFlags;
				public c_short usButtonData;
			}

			public c_ulong ulButtons;
			public using DUMMYSTRUCTNAME data;
		}

		/*
		 * Indicator flags.
		 */
		public c_ushort usFlags;

		/*
		 * The transition state of the mouse buttons.
		 */
		public using DUMMYUNIONNAME unionData;


		/*
		 * The raw state of the mouse buttons.
		 */
		public c_ulong ulRawButtons;

		/*
		 * The signed relative or absolute motion in the X direction.
		 */
		public c_long lLastX;

		/*
		 * The signed relative or absolute motion in the Y direction.
		 */
		public c_long lLastY;

		/*
		 * Device-specific additional information for the event.
		 */
		public c_ulong ulExtraInformation;
	}

	[CRepr]
	public struct RAWKEYBOARD
	{
		/*
		 * The "make" scan code (key depression).
		 */
		public c_ushort MakeCode;

		/*
		 * The flags field indicates a "break" (key release) and other
		 * miscellaneous scan code information defined in ntddkbd.h.
		 */
		public c_ushort Flags;

		public c_ushort Reserved;

		/*
		 * Windows message compatible information
		 */
		public c_ushort VKey;
		public c_uint   Message;

		/*
		 * Device-specific additional information for the event.
		 */
		public c_ulong ExtraInformation;
	}

	[CRepr]
	public struct RAWHID
	{
		public c_ulong dwSizeHid;    // byte size of each report
		public c_ulong dwCount;      // number of input packed
		public uint8[1] bRawData;
		public uint8* RawData mut => &bRawData;
	}

	[CRepr]
	public struct RAWINPUT
	{
		[CRepr, Union]
		public struct Data
		{
			public RAWMOUSE mouse;
			public RAWKEYBOARD keyboard;
			public RAWHID hid;
		}

		public RAWINPUTHEADER header;
		public using Data data;
	}

	[CRepr]
	public struct NOTIFYICONDATAW
	{
		public c_ulong cbSize;
		public Windows.HWnd hWnd;
		public c_uint uID;
		public c_uint uFlags;
		public c_uint uCallbackMessage;
		public HIcon hIcon;
		public c_wchar[128]  szTip;
		public c_ulong dwState;
		public c_ulong dwStateMask;
		public c_wchar[256]  szInfo;
		[CRepr, Union]
		public struct DUMMYUNIONNAME{
		    public c_uint  uTimeout;
		    public c_uint  uVersion;  // used with NIM_SETVERSION, values 0, 3 and 4
		}
		using public DUMMYUNIONNAME dummyunion;
		public c_wchar[64]  szInfoTitle;
		public c_ulong dwInfoFlags;
		public Guid guidItem;
		public HIcon hBalloonIcon;
	}

	[CRepr]
	public struct INPUT
	{
		public enum TYPE : c_int
		{
			Mouse = 0,
			Keyboard = 1,
			Hardware = 2
		}

		[CRepr]
		public struct MOUSEINPUT
		{
			public c_long dx;
			public c_long dy;
			public c_int mouseData;
			public c_int dwFlags;
			public c_int time;
			public uint dwExtraInfo;
		}

		[CRepr]
		public struct KEYBDINPUT
		{
			public c_short wVk;
			public c_short wScan;
			public c_int dwFlags;
			public c_int time;
			public uint dwExtraInfo;

			public static Self KeyDown(c_short vk) => Self() {wVk = vk};
			public static Self KeyUp(c_short vk) => Self() {wVk = vk, dwFlags = KEYEVENTF_KEYUP};
		}

		[CRepr]
		public struct HARDWAREINPUT
		{
			public c_int uMsg;
			public c_short wParamL;
			public c_short wParamH;
		}

		[CRepr, Union]
		struct UNION
		{
			public MOUSEINPUT mouse;
			public KEYBDINPUT keyboard;
			public HARDWAREINPUT hardware;
		}

		public TYPE type;
		public using UNION union;

		public static Self CreateMouse(MOUSEINPUT mi) => .{ type = .Mouse, mouse = mi };
		public static Self CreateKeyboard(KEYBDINPUT ki) => .{ type = .Keyboard, keyboard = ki };

	}

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool RegisterRawInputDevices(RAWINPUTDEVICE* pRawInputDevices, c_uint uiNumDevices, c_uint cbSize);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_uint GetRawInputData(RAWINPUT* hRawInput, c_uint uiCommand, void* pData, c_uint* pcbSize, c_uint cbSizeHeader);

	[CallingConvention(.Stdcall)]
	function Windows.IntBool MONITORENUMPROC(HMonitor hMonitor, HDC hdc, RECT* lpRect, int lParam);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool EnumDisplayMonitors(HDC hdc, RECT* lprcClip, MONITORENUMPROC lpfnEnum, int dwData);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool GetMonitorInfoW(HMonitor hMonitor, MONITORINFO* lpmi);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool TrackMouseEvent(TRACKMOUSEEVENT* lpEventTrack);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool SwapBuffers(HDC hdc);

	[CLink, CallingConvention(.Stdcall)]
	public static extern HDC GetDC(Windows.HWnd hWnd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int ChoosePixelFormat(HDC hdc, PIXELFORMATDESCRIPTOR* ppfd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int SetPixelFormat(HDC hdc, c_int format, PIXELFORMATDESCRIPTOR* ppfd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int DescribePixelFormat(HDC hdc, c_int format, c_uint nBytes, PIXELFORMATDESCRIPTOR* ppfd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int FlashWindowEx(FLASHWINFO* pfwi);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int SetWindowTextW(Windows.HWnd hWnd, char16* text);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int ShowWindow(Windows.HWnd hWnd, c_int nCmdShow);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int SetWindowPos(Windows.HWnd hWnd, Windows.HWnd hWndInsertAfter, c_int x, c_int y, c_int cx, c_int cy, c_uint uFlags);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool BringWindowToTop(Windows.HWnd hWnd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool SetForegroundWindow(Windows.HWnd hWnd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.HWnd GetForegroundWindow();

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.HWnd SetFocus(Windows.HWnd hWnd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool EnableWindow(Windows.HWnd hWnd, Windows.IntBool bEnable);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.HWnd WindowFromPoint(POINT point);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool DestroyWindow(Windows.HWnd hWnd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool IsWindow(Windows.HWnd hWnd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.HWnd GetParent(Windows.HWnd hWnd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_ushort RegisterClassExW(WNDCLASSEXW* pWndClassEx);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.HWnd CreateWindowExW(c_ulong dwExStyle, char16* lpClassName, char16* lpWindowName, c_ulong dwStyle, c_int X, c_int Y, c_int nWidth, c_int nHeight, Windows.HWnd hWndParent, void* hMenu, Windows.HInstance hInstance, void* lpParam);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_longlong DefWindowProcW(Windows.HWnd hwnd, c_uint uMsg, uint wParam, int lParam);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int PeekMessageW(MSG* lpMsg, Windows.HWnd hWnd, c_uint wMsgFilterMin, c_uint wMsgFilterMax, c_uint wRemoveMsg);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool GetMessageW(MSG* lpMsg, Windows.HWnd hWnd, c_uint wMsgFilterMin, c_uint wMsgFilterMax);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int TranslateMessage(MSG* msg);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_int DispatchMessageW(MSG* msg);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool GetCursorPos(POINT* lpPoint);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool SetCursorPos(c_int x, c_int y);

	[CLink, CallingConvention(.Stdcall)]
	public static extern HCursor SetCursor(HCursor hCursor);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool ClipCursor(RECT* lpRect);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.HWnd SetCapture(Windows.HWnd hWnd);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool ReleaseCapture();

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_ulong FormatMessageW(c_uint dwFlags, void* lpSource, c_uint dwMessageId, c_uint dwLanguageId, char16* lpBuffer, c_uint nSize, VarArgs* Arguments);

	public static bool GetLastErrorAsString(String buffer)
	{
		const int FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100;
		const int FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200;
		const int FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000;

		//Get the error message ID, if any.
		let error = Windows.GetLastError();
		if (error == 0)
		{
			return true;
		}

		char16* messageBuffer = null;
		//Ask Win32 to give us the string version of that message ID.
		//The parameters we pass in, tell Win32 to create the buffer that holds the message for us (because we don't yet know how long the message string will be).
		let size = FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, null, (.)error, 0, (.)&messageBuffer, 0, null);
		defer Windows.LocalFree(messageBuffer);

		buffer.AppendF($"({error})");
		if (size > 0)
		{
			switch (System.Text.Encoding.UTF16.DecodeToUTF8(.((uint8*)messageBuffer, size * sizeof(char16)), buffer))
			{
			case .Ok(let val):
				return true;
			case .Err(let err): break;
			}
		}

		//Free the Win32's string's buffer.
		Windows.LocalFree(&messageBuffer);
		return false;
	}

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool AdjustWindowRectEx(RECT* lpRect, c_uint dwStyle, Windows.IntBool bMenu, c_uint dwExStyle);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool GetWindowRect(Windows.HWnd hWnd, RECT* pRect);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool GetClientRect(Windows.HWnd hWnd, RECT* pRect);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool ClientToScreen(Windows.HWnd hWnd, POINT* pRect);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool ScreenToClient(Windows.HWnd hWnd, POINT* pRect);

	[CLink, CallingConvention(.Stdcall)]
	public static extern HCursor LoadCursorW(Windows.HInstance hInst, char16* lpCursorName);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_uint MapVirtualKeyW(c_uint uCode, c_uint uMapType);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool SetLayeredWindowAttributes(Windows.HWnd hWnd, c_long crKey, uint8 bAlpha, c_ulong dwFlags);

	struct HResult : c_long;
		
	[CLink, CallingConvention(.Stdcall)]
	public static extern HResult CoInitialize(void* pvReserved);

	[CLink, CallingConvention(.Stdcall)]
	public static extern void CoUninitialize();

	struct ITEMIDLIST;
	[CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILCreateFromPathW(char16* pzspath);

	[CLink, CallingConvention(.Stdcall)]
	public static extern HResult SHOpenFolderAndSelectItems(ITEMIDLIST* pidFolder, c_uint cidl, ITEMIDLIST** apidl, c_ulong dwFlags);

	struct HGlobal : Windows.Handle {}

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.Handle GetClipboardData(c_uint uFormat);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.Handle SetClipboardData(c_uint uFormat, Windows.Handle mem);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool OpenClipboard(Windows.HWnd hWndNewOwner);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool EmptyClipboard();

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool CloseClipboard();

	[CLink, CallingConvention(.Stdcall)]
	public static extern HGlobal GlobalAlloc(c_int uFlags, c_intptr dwBytes);

	[CLink, CallingConvention(.Stdcall)]
	public static extern void* GlobalLock(Windows.Handle hMem);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool GlobalUnlock(Windows.Handle hMem);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool Shell_NotifyIconW(c_ulong dwMessage, NOTIFYICONDATAW* lpData);

	[CLink, CallingConvention(.Stdcall)]
	public static extern HIcon LoadIconW(Windows.HInstance hInstance, c_wchar* lpIconName);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.Handle LoadImageW(Windows.HInstance hInstance, c_wchar* name, c_uint type, c_int cx, c_int cy, c_uint fuLoad);

	[CLink, CallingConvention(.Stdcall)]
	public static extern HMenu CreatePopupMenu();

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool DestroyMenu(HMenu hMenu);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool AppendMenuW(HMenu hMenum, c_uint uFlags, c_ulonglong uIDNewItem, c_wchar* lpNewItem);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool TrackPopupMenu(HMenu hMenu, c_uint uFlags, c_int x, c_int y, c_int nReserved, Windows.HWnd hWnd, /*const*/ RECT* prcRect);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool ModifyMenuW(HMenu hMenu, c_uint uPosition, c_uint uFlags, c_uintptr uIDNewItem, c_wchar* lpNewItem);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_uint CheckMenuItem(HMenu hMenu, c_uint uIDCheckItem, c_uint uCheck);

	[CLink, CallingConvention(.Stdcall)]
	public static extern c_uint SendInput(c_uint cInputs, INPUT* pInputs, c_int cbSize);

	[CLink, CallingConvention(.Stdcall)]
	public static extern Windows.IntBool RegisterHotKey(Windows.HWnd hWnd, c_int id, c_uint fsModifiers, c_uint vk);

	[CLink, CallingConvention(.Stdcall)]
	public static extern void PostQuitMessage(c_int nExitCode);

	[CLink, CallingConvention(.Stdcall)]
	public static extern void PostMessageW(Windows.HWnd hWnd, c_uint Msg, uint wParam, int lParam);

	public const int MONITORINFOF_PRIMARY = 0x00000001;
	public const int CCHDEVICENAME = 32;

	/*
	 * PeekMessage() Options
	 */
	public const int PM_NOREMOVE = 0x0000;
	public const int PM_REMOVE = 0x0001;
	public const int PM_NOYIELD = 0x0002;

	/*
	* Window Styles
	*/
	public const int WS_OVERLAPPED = 0x00000000L;
	public const int WS_POPUP = 0x80000000L;
	public const int WS_CHILD = 0x40000000L;
	public const int WS_MINIMIZE = 0x20000000L;
	public const int WS_VISIBLE = 0x10000000L;
	public const int WS_DISABLED = 0x08000000L;
	public const int WS_CLIPSIBLINGS = 0x04000000L;
	public const int WS_CLIPCHILDREN = 0x02000000L;
	public const int WS_MAXIMIZE = 0x01000000L;
	public const int WS_CAPTION = 0x00C00000L;
	public const int WS_BORDER = 0x00800000L;
	public const int WS_DLGFRAME = 0x00400000L;
	public const int WS_VSCROLL = 0x00200000L;
	public const int WS_HSCROLL = 0x00100000L;
	public const int WS_SYSMENU = 0x00080000L;
	public const int WS_THICKFRAME = 0x00040000L;
	public const int WS_GROUP = 0x00020000L;
	public const int WS_TABSTOP = 0x00010000L;
	public const int WS_MINIMIZEBOX = 0x00020000L;
	public const int WS_MAXIMIZEBOX = 0x00010000L;
	public const int WS_TILED = WS_OVERLAPPED;
	public const int WS_ICONIC = WS_MINIMIZE;
	public const int WS_SIZEBOX = WS_THICKFRAME;
	public const int WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW;

	/*
	* Common Window Styles
	*/
	public const int WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
	public const int WS_POPUPWINDOW = (WS_POPUP | WS_BORDER | WS_SYSMENU);

	/*
	* Extended Window Styles
	*/
	public const int WS_EX_DLGMODALFRAME = 0x00000001L;
	public const int WS_EX_NOPARENTNOTIFY = 0x00000004L;
	public const int WS_EX_TOPMOST = 0x00000008L;
	public const int WS_EX_ACCEPTFILES = 0x00000010L;
	public const int WS_EX_TRANSPARENT = 0x00000020L;
	public const int WS_EX_MDICHILD = 0x00000040L;
	public const int WS_EX_TOOLWINDOW = 0x00000080L;
	public const int WS_EX_WINDOWEDGE = 0x00000100L;
	public const int WS_EX_CLIENTEDGE = 0x00000200L;
	public const int WS_EX_CONTEXTHELP = 0x00000400L;
	public const int WS_EX_RIGHT = 0x00001000L;
	public const int WS_EX_LEFT = 0x00000000L;
	public const int WS_EX_RTLREADING = 0x00002000L;
	public const int WS_EX_LTRREADING = 0x00000000L;
	public const int WS_EX_LEFTSCROLLBAR = 0x00004000L;
	public const int WS_EX_RIGHTSCROLLBAR = 0x00000000L;
	public const int WS_EX_CONTROLPARENT = 0x00010000L;
	public const int WS_EX_STATICEDGE = 0x00020000L;
	public const int WS_EX_APPWINDOW = 0x00040000L;
	public const int WS_EX_OVERLAPPEDWINDOW = (WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE);
	public const int WS_EX_PALETTEWINDOW = (WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST);
	public const int WS_EX_LAYERED = 0x00080000;
	public const int WS_EX_NOINHERITLAYOUT = 0x00100000L;
	public const int WS_EX_NOREDIRECTIONBITMAP = 0x00200000L;
	public const int WS_EX_LAYOUTRTL = 0x00400000L;
	public const int WS_EX_COMPOSITED = 0x02000000L;
	public const int WS_EX_NOACTIVATE = 0x08000000L;

	/*
	* Class styles
	*/

	public const int CS_VREDRAW = 0x0001;
	public const int CS_HREDRAW = 0x0002;
	public const int CS_DBLCLKS = 0x0008;
	public const int CS_OWNDC = 0x0020;
	public const int CS_CLASSDC = 0x0040;
	public const int CS_PARENTDC = 0x0080;
	public const int CS_NOCLOSE = 0x0200;
	public const int CS_SAVEBITS = 0x0800;
	public const int CS_BYTEALIGNCLIENT = 0x1000;
	public const int CS_BYTEALIGNWINDOW = 0x2000;
	public const int CS_GLOBALCLASS = 0x4000;
	public const int CS_IME = 0x00010000;
	public const int CS_DROPSHADOW = 0x00020000;

	/*
	* Window field offsets for GetWindowLong()
	*/
	public const int GWL_WNDPROC = (-4);
	public const int GWL_HINSTANCE = (-6);
	public const int GWL_HWNDPARENT = (-8);
	public const int GWL_STYLE = (-16);
	public const int GWL_EXSTYLE = (-20);
	public const int GWL_USERDATA = (-21);
	public const int GWL_ID = (-12);
	public const int GWLP_WNDPROC = (-4);
	public const int GWLP_HINSTANCE = (-6);
	public const int GWLP_HWNDPARENT = (-8);
	public const int GWLP_USERDATA = (-21);
	public const int GWLP_ID = (-12);

	/*
	 * SetWindowPos Flags
	 */
	public const int SWP_NOSIZE = 0x0001;
	public const int SWP_NOMOVE = 0x0002;
	public const int SWP_NOZORDER = 0x0004;
	public const int SWP_NOREDRAW = 0x0008;
	public const int SWP_NOACTIVATE = 0x0010;
	public const int SWP_FRAMECHANGED = 0x0020; /* The frame changed: send WM_NCCALCSIZE */
	public const int SWP_SHOWWINDOW = 0x0040;
	public const int SWP_HIDEWINDOW = 0x0080;
	public const int SWP_NOCOPYBITS = 0x0100;
	public const int SWP_NOOWNERZORDER = 0x0200; /* Don't do owner Z ordering */
	public const int SWP_NOSENDCHANGING = 0x0400; /* Don't send WM_WINDOWPOSCHANGING */

	public const int SWP_DRAWFRAME = SWP_FRAMECHANGED;
	public const int SWP_NOREPOSITION = SWP_NOOWNERZORDER;

	public const int SWP_DEFERERASE = 0x2000;
	public const int SWP_ASYNCWINDOWPOS = 0x4000;

	public const Windows.HWnd HWND_TOP = ((Windows.HWnd)0);
	public const Windows.HWnd HWND_BOTTOM = ((Windows.HWnd)1);
	public const Windows.HWnd HWND_TOPMOST = ((Windows.HWnd) - 1);
	public const Windows.HWnd HWND_NOTOPMOST = ((Windows.HWnd) - 2);

	/*
	 * ShowWindow() Commands
	 */

	public const int SW_HIDE = 0;
	public const int SW_SHOWNORMAL = 1;
	public const int SW_NORMAL = 1;
	public const int SW_SHOWMINIMIZED = 2;
	public const int SW_SHOWMAXIMIZED = 3;
	public const int SW_MAXIMIZE = 3;
	public const int SW_SHOWNOACTIVATE = 4;
	public const int SW_SHOW = 5;
	public const int SW_MINIMIZE = 6;
	public const int SW_SHOWMINNOACTIVE = 7;
	public const int SW_SHOWNA = 8;
	public const int SW_RESTORE = 9;
	public const int SW_SHOWDEFAULT = 10;
	public const int SW_FORCEMINIMIZE = 11;
	public const int SW_MAX = 11;

	/*
	 * FlashWindowEx() Flags
	 */

	public const int FLASHW_STOP = 0;
	public const int FLASHW_CAPTION = 0;
	public const int FLASHW_TRAY = 0;
	public const int FLASHW_ALL = (FLASHW_CAPTION | FLASHW_TRAY);
	public const int FLASHW_TIMER = 0;
	public const int FLASHW_TIMERNOFG = 0;

	/*
	* Pixel format descriptor 
	*/

	/* pixel types */
	public const int PFD_TYPE_RGBA =        0;
	public const int PFD_TYPE_COLORINDEX =  1;

	/* layer types */
	public const int PFD_MAIN_PLANE =       0;
	public const int PFD_OVERLAY_PLANE =    1;
	public const int PFD_UNDERLAY_PLANE =   (-1);

	/* PIXELFORMATDESCRIPTOR flags */
	public const int PFD_DOUBLEBUFFER =            0x00000001;
	public const int PFD_STEREO =                  0x00000002;
	public const int PFD_DRAW_TO_WINDOW =          0x00000004;
	public const int PFD_DRAW_TO_BITMAP =          0x00000008;
	public const int PFD_SUPPORT_GDI =             0x00000010;
	public const int PFD_SUPPORT_OPENGL =          0x00000020;
	public const int PFD_GENERIC_FORMAT =          0x00000040;
	public const int PFD_NEED_PALETTE =            0x00000080;
	public const int PFD_NEED_SYSTEM_PALETTE =     0x00000100;
	public const int PFD_SWAP_EXCHANGE =           0x00000200;
	public const int PFD_SWAP_COPY =               0x00000400;
	public const int PFD_SWAP_LAYER_BUFFERS =      0x00000800;
	public const int PFD_GENERIC_ACCELERATED =     0x00001000;
	public const int PFD_SUPPORT_DIRECTDRAW =      0x00002000;
	public const int PFD_DIRECT3D_ACCELERATED =   0x00004000;
	public const int PFD_SUPPORT_COMPOSITION =     0x00008000;

	/* PIXELFORMATDESCRIPTOR flags for use in ChoosePixelFormat only */
	public const int PFD_DEPTH_DONTCARE =          0x20000000;
	public const int PFD_DOUBLEBUFFER_DONTCARE =   0x40000000;
	public const int PFD_STEREO_DONTCARE =         0x80000000;

	/*
	* Window Messages
	*/

	public const int WM_NULL = 0x0000;
	public const int WM_CREATE = 0x0001;
	public const int WM_DESTROY = 0x0002;
	public const int WM_MOVE = 0x0003;
	public const int WM_SIZE = 0x0005;
	public const int WM_ACTIVATE = 0x0006;
	public const int WM_SETFOCUS = 0x0007;
	public const int WM_KILLFOCUS = 0x0008;
	public const int WM_ENABLE = 0x000A;
	public const int WM_SETREDRAW = 0x000B;
	public const int WM_SETTEXT = 0x000C;
	public const int WM_GETTEXT = 0x000D;
	public const int WM_GETTEXTLENGTH = 0x000E;
	public const int WM_PAINT = 0x000F;
	public const int WM_CLOSE = 0x0010;
	public const int WM_QUERYENDSESSION = 0x0011;
	public const int WM_QUERYOPEN = 0x0013;
	public const int WM_ENDSESSION = 0x0016;
	public const int WM_QUIT = 0x0012;
	public const int WM_ERASEBKGND = 0x0014;
	public const int WM_SYSCOLORCHANGE = 0x0015;
	public const int WM_SHOWWINDOW = 0x0018;
	public const int WM_WININICHANGE = 0x001A;
	public const int WM_SETTINGCHANGE = WM_WININICHANGE;
	public const int WM_DEVMODECHANGE = 0x001B;
	public const int WM_ACTIVATEAPP = 0x001C;
	public const int WM_FONTCHANGE = 0x001D;
	public const int WM_TIMECHANGE = 0x001E;
	public const int WM_CANCELMODE = 0x001F;
	public const int WM_SETCURSOR = 0x0020;
	public const int WM_MOUSEACTIVATE = 0x0021;
	public const int WM_CHILDACTIVATE = 0x0022;
	public const int WM_QUEUESYNC = 0x0023;
	public const int WM_GETMINMAXINFO = 0x0024;
	public const int WM_PAINTICON = 0x0026;
	public const int WM_ICONERASEBKGND = 0x0027;
	public const int WM_NEXTDLGCTL = 0x0028;
	public const int WM_SPOOLERSTATUS = 0x002A;
	public const int WM_DRAWITEM = 0x002B;
	public const int WM_MEASUREITEM = 0x002C;
	public const int WM_DELETEITEM = 0x002D;
	public const int WM_VKEYTOITEM = 0x002E;
	public const int WM_CHARTOITEM = 0x002F;
	public const int WM_SETFONT = 0x0030;
	public const int WM_GETFONT = 0x0031;
	public const int WM_SETHOTKEY = 0x0032;
	public const int WM_GETHOTKEY = 0x0033;
	public const int WM_QUERYDRAGICON = 0x0037;
	public const int WM_COMPAREITEM = 0x0039;
	public const int WM_GETOBJECT = 0x003D;
	public const int WM_COMPACTING = 0x0041;
	public const int WM_COMMNOTIFY = 0x0044;
	public const int WM_WINDOWPOSCHANGING = 0x0046;
	public const int WM_WINDOWPOSCHANGED = 0x0047;
	public const int WM_POWER = 0x0048;
	public const int WM_COPYDATA = 0x004A;
	public const int WM_CANCELJOURNAL = 0x004B;
	public const int WM_NOTIFY = 0x004E;
	public const int WM_INPUTLANGCHANGEREQUEST = 0x0050;
	public const int WM_INPUTLANGCHANGE = 0x0051;
	public const int WM_TCARD = 0x0052;
	public const int WM_HELP = 0x0053;
	public const int WM_USERCHANGED = 0x0054;
	public const int WM_NOTIFYFORMAT = 0x0055;
	public const int WM_CONTEXTMENU = 0x007B;
	public const int WM_STYLECHANGING = 0x007C;
	public const int WM_STYLECHANGED = 0x007D;
	public const int WM_DISPLAYCHANGE = 0x007E;
	public const int WM_GETICON = 0x007F;
	public const int WM_SETICON = 0x0080;
	public const int WM_NCCREATE = 0x0081;
	public const int WM_NCDESTROY = 0x0082;
	public const int WM_NCCALCSIZE = 0x0083;
	public const int WM_NCHITTEST = 0x0084;
	public const int WM_NCPAINT = 0x0085;
	public const int WM_NCACTIVATE = 0x0086;
	public const int WM_GETDLGCODE = 0x0087;
	public const int WM_SYNCPAINT = 0x0088;
	public const int WM_NCMOUSEMOVE = 0x00A0;
	public const int WM_NCLBUTTONDOWN = 0x00A1;
	public const int WM_NCLBUTTONUP = 0x00A2;
	public const int WM_NCLBUTTONDBLCLK = 0x00A3;
	public const int WM_NCRBUTTONDOWN = 0x00A4;
	public const int WM_NCRBUTTONUP = 0x00A5;
	public const int WM_NCRBUTTONDBLCLK = 0x00A6;
	public const int WM_NCMBUTTONDOWN = 0x00A7;
	public const int WM_NCMBUTTONUP = 0x00A8;
	public const int WM_NCMBUTTONDBLCLK = 0x00A9;
	public const int WM_NCXBUTTONDOWN = 0x00AB;
	public const int WM_NCXBUTTONUP = 0x00AC;
	public const int WM_NCXBUTTONDBLCLK = 0x00AD;
	public const int WM_INPUT_DEVICE_CHANGE = 0x00FE;
	public const int WM_INPUT = 0x00FF;
	public const int WM_KEYFIRST = 0x0100;
	public const int WM_KEYDOWN = 0x0100;
	public const int WM_KEYUP = 0x0101;
	public const int WM_CHAR = 0x0102;
	public const int WM_DEADCHAR = 0x0103;
	public const int WM_SYSKEYDOWN = 0x0104;
	public const int WM_SYSKEYUP = 0x0105;
	public const int WM_SYSCHAR = 0x0106;
	public const int WM_SYSDEADCHAR = 0x0107;
	public const int WM_UNICHAR = 0x0109;
	public const int WM_KEYLAST = 0x0109;
	public const int WM_IME_STARTCOMPOSITION = 0x010D;
	public const int WM_IME_ENDCOMPOSITION = 0x010E;
	public const int WM_IME_COMPOSITION = 0x010F;
	public const int WM_IME_KEYLAST = 0x010F;
	public const int WM_INITDIALOG = 0x0110;
	public const int WM_COMMAND = 0x0111;
	public const int WM_SYSCOMMAND = 0x0112;
	public const int WM_TIMER = 0x0113;
	public const int WM_HSCROLL = 0x0114;
	public const int WM_VSCROLL = 0x0115;
	public const int WM_INITMENU = 0x0116;
	public const int WM_INITMENUPOPUP = 0x0117;
	public const int WM_GESTURE = 0x0119;
	public const int WM_GESTURENOTIFY = 0x011A;
	public const int WM_MENUSELECT = 0x011F;
	public const int WM_MENUCHAR = 0x0120;
	public const int WM_ENTERIDLE = 0x0121;
	public const int WM_MENURBUTTONUP = 0x0122;
	public const int WM_MENUDRAG = 0x0123;
	public const int WM_MENUGETOBJECT = 0x0124;
	public const int WM_UNINITMENUPOPUP = 0x0125;
	public const int WM_MENUCOMMAND = 0x0126;
	public const int WM_CHANGEUISTATE = 0x0127;
	public const int WM_UPDATEUISTATE = 0x0128;
	public const int WM_QUERYUISTATE = 0x0129;
	public const int WM_CTLCOLORMSGBOX = 0x0132;
	public const int WM_CTLCOLOREDIT = 0x0133;
	public const int WM_CTLCOLORLISTBOX = 0x0134;
	public const int WM_CTLCOLORBTN = 0x0135;
	public const int WM_CTLCOLORDLG = 0x0136;
	public const int WM_CTLCOLORSCROLLBAR = 0x0137;
	public const int WM_CTLCOLORSTATIC = 0x0138;
	public const int WM_MOUSEFIRST = 0x0200;
	public const int WM_MOUSEMOVE = 0x0200;
	public const int WM_LBUTTONDOWN = 0x0201;
	public const int WM_LBUTTONUP = 0x0202;
	public const int WM_LBUTTONDBLCLK = 0x0203;
	public const int WM_RBUTTONDOWN = 0x0204;
	public const int WM_RBUTTONUP = 0x0205;
	public const int WM_RBUTTONDBLCLK = 0x0206;
	public const int WM_MBUTTONDOWN = 0x0207;
	public const int WM_MBUTTONUP = 0x0208;
	public const int WM_MBUTTONDBLCLK = 0x0209;
	public const int WM_MOUSEWHEEL = 0x020A;
	public const int WM_XBUTTONDOWN = 0x020B;
	public const int WM_XBUTTONUP = 0x020C;
	public const int WM_XBUTTONDBLCLK = 0x020D;
	public const int WM_MOUSEHWHEEL = 0x020E;
	public const int WM_MOUSELAST = 0x020E;
	public const int WM_PARENTNOTIFY = 0x0210;
	public const int WM_ENTERMENULOOP = 0x0211;
	public const int WM_EXITMENULOOP = 0x0212;
	public const int WM_NEXTMENU = 0x0213;
	public const int WM_SIZING = 0x0214;
	public const int WM_CAPTURECHANGED = 0x0215;
	public const int WM_MOVING = 0x0216;
	public const int WM_POWERBROADCAST = 0x0218;
	public const int WM_DEVICECHANGE = 0x0219;
	public const int WM_MDICREATE = 0x0220;
	public const int WM_MDIDESTROY = 0x0221;
	public const int WM_MDIACTIVATE = 0x0222;
	public const int WM_MDIRESTORE = 0x0223;
	public const int WM_MDINEXT = 0x0224;
	public const int WM_MDIMAXIMIZE = 0x0225;
	public const int WM_MDITILE = 0x0226;
	public const int WM_MDICASCADE = 0x0227;
	public const int WM_MDIICONARRANGE = 0x0228;
	public const int WM_MDIGETACTIVE = 0x0229;
	public const int WM_MDISETMENU = 0x0230;
	public const int WM_ENTERSIZEMOVE = 0x0231;
	public const int WM_EXITSIZEMOVE = 0x0232;
	public const int WM_DROPFILES = 0x0233;
	public const int WM_MDIREFRESHMENU = 0x0234;
	public const int WM_POINTERDEVICECHANGE = 0x238;
	public const int WM_POINTERDEVICEINRANGE = 0x239;
	public const int WM_POINTERDEVICEOUTOFRANGE = 0x23A;
	public const int WM_TOUCH = 0x0240;
	public const int WM_NCPOINTERUPDATE = 0x0241;
	public const int WM_NCPOINTERDOWN = 0x0242;
	public const int WM_NCPOINTERUP = 0x0243;
	public const int WM_POINTERUPDATE = 0x0245;
	public const int WM_POINTERDOWN = 0x0246;
	public const int WM_POINTERUP = 0x0247;
	public const int WM_POINTERENTER = 0x0249;
	public const int WM_POINTERLEAVE = 0x024A;
	public const int WM_POINTERACTIVATE = 0x024B;
	public const int WM_POINTERCAPTURECHANGED = 0x024C;
	public const int WM_TOUCHHITTESTING = 0x024D;
	public const int WM_POINTERWHEEL = 0x024E;
	public const int WM_POINTERHWHEEL = 0x024F;
	public const int WM_POINTERROUTEDTO = 0x0251;
	public const int WM_POINTERROUTEDAWAY = 0x0252;
	public const int WM_POINTERROUTEDRELEASED = 0x0253;
	public const int WM_IME_SETCONTEXT = 0x0281;
	public const int WM_IME_NOTIFY = 0x0282;
	public const int WM_IME_CONTROL = 0x0283;
	public const int WM_IME_COMPOSITIONFULL = 0x0284;
	public const int WM_IME_SELECT = 0x0285;
	public const int WM_IME_CHAR = 0x0286;
	public const int WM_IME_REQUEST = 0x0288;
	public const int WM_IME_KEYDOWN = 0x0290;
	public const int WM_IME_KEYUP = 0x0291;
	public const int WM_MOUSEHOVER = 0x02A1;
	public const int WM_MOUSELEAVE = 0x02A3;
	public const int WM_NCMOUSEHOVER = 0x02A0;
	public const int WM_NCMOUSELEAVE = 0x02A2;
	public const int WM_WTSSESSION_CHANGE = 0x02B1;
	public const int WM_TABLET_FIRST = 0x02c0;
	public const int WM_TABLET_LAST = 0x02df;
	public const int WM_DPICHANGED = 0x02E0;
	public const int WM_DPICHANGED_BEFOREPARENT = 0x02E2;
	public const int WM_DPICHANGED_AFTERPARENT = 0x02E3;
	public const int WM_GETDPISCALEDSIZE = 0x02E4;
	public const int WM_CUT = 0x0300;
	public const int WM_COPY = 0x0301;
	public const int WM_PASTE = 0x0302;
	public const int WM_CLEAR = 0x0303;
	public const int WM_UNDO = 0x0304;
	public const int WM_RENDERFORMAT = 0x0305;
	public const int WM_RENDERALLFORMATS = 0x0306;
	public const int WM_DESTROYCLIPBOARD = 0x0307;
	public const int WM_DRAWCLIPBOARD = 0x0308;
	public const int WM_PAINTCLIPBOARD = 0x0309;
	public const int WM_VSCROLLCLIPBOARD = 0x030A;
	public const int WM_SIZECLIPBOARD = 0x030B;
	public const int WM_ASKCBFORMATNAME = 0x030C;
	public const int WM_CHANGECBCHAIN = 0x030D;
	public const int WM_HSCROLLCLIPBOARD = 0x030E;
	public const int WM_QUERYNEWPALETTE = 0x030F;
	public const int WM_PALETTEISCHANGING = 0x0310;
	public const int WM_PALETTECHANGED = 0x0311;
	public const int WM_HOTKEY = 0x0312;
	public const int WM_PRINT = 0x0317;
	public const int WM_PRINTCLIENT = 0x0318;
	public const int WM_APPCOMMAND = 0x0319;
	public const int WM_THEMECHANGED = 0x031A;
	public const int WM_CLIPBOARDUPDATE = 0x031D;
	public const int WM_DWMCOMPOSITIONCHANGED = 0x031E;
	public const int WM_DWMNCRENDERINGCHANGED = 0x031F;
	public const int WM_DWMCOLORIZATIONCOLORCHANGED = 0x0320;
	public const int WM_DWMWINDOWMAXIMIZEDCHANGE = 0x0321;
	public const int WM_DWMSENDICONICTHUMBNAIL = 0x0323;
	public const int WM_DWMSENDICONICLIVEPREVIEWBITMAP = 0x0326;
	public const int WM_GETTITLEBARINFOEX = 0x033F;
	public const int WM_HANDHELDFIRST = 0x0358;
	public const int WM_HANDHELDLAST = 0x035F;
	public const int WM_AFXFIRST = 0x0360;
	public const int WM_AFXLAST = 0x037F;
	public const int WM_PENWINFIRST = 0x0380;
	public const int WM_PENWINLAST = 0x038F;
	public const int WM_APP = 0x8000;
	public const int WM_USER = 0x0400;

	/*
	* TrackMouseEvent flags
	*/

	public const int TME_HOVER = 0x00000001;
	public const int TME_LEAVE = 0x00000002;
	public const int TME_NONCLIENT = 0x00000010;
	public const int TME_QUERY = 0x40000000;
	public const int TME_CANCEL = 0x80000000;

	/*
	* Standard Cursor IDs
	*/

	public const char16* IDC_ARROW = (char16*)(void*)32512;
	public const char16* IDC_IBEAM = (char16*)(void*)32513;
	public const char16* IDC_WAIT = (char16*)(void*)32514;
	public const char16* IDC_CROSS = (char16*)(void*)32515;
	public const char16* IDC_UPARROW = (char16*)(void*)32516;
	public const char16* IDC_SIZE = (char16*)(void*)32640;
	public const char16* IDC_ICON = (char16*)(void*)32641;
	public const char16* IDC_SIZENWSE = (char16*)(void*)32642;
	public const char16* IDC_SIZENESW = (char16*)(void*)32643;
	public const char16* IDC_SIZEWE = (char16*)(void*)32644;
	public const char16* IDC_SIZENS = (char16*)(void*)32645;
	public const char16* IDC_SIZEALL = (char16*)(void*)32646;
	public const char16* IDC_NO = (char16*)(void*)32648;
	public const char16* IDC_HAND = (char16*)(void*)32649;
	public const char16* IDC_APPSTARTING = (char16*)(void*)32650;
	public const char16* IDC_HELP = (char16*)(void*)32651;
	public const char16* IDC_PIN = (char16*)(void*)32671;
	public const char16* IDC_PERSON = (char16*)(void*)32672;

	/*
	* Virtual Keys, Standard Set
	*/

	public const int VK_LBUTTON = 0x01;
	public const int VK_RBUTTON = 0x02;
	public const int VK_CANCEL = 0x03;
	public const int VK_MBUTTON = 0x04;
	public const int VK_XBUTTON1 = 0x05;
	public const int VK_XBUTTON2 = 0x06;
	public const int VK_BACK = 0x08;
	public const int VK_TAB = 0x09;
	public const int VK_CLEAR = 0x0C;
	public const int VK_RETURN = 0x0D;
	public const int VK_SHIFT = 0x10;
	public const int VK_CONTROL = 0x11;
	public const int VK_MENU = 0x12;
	public const int VK_PAUSE = 0x13;
	public const int VK_CAPITAL = 0x14;
	public const int VK_KANA = 0x15;
	public const int VK_HANGEUL = 0x15;
	public const int VK_HANGUL = 0x15;
	public const int VK_IME_ON = 0x16;
	public const int VK_JUNJA = 0x17;
	public const int VK_FINAL = 0x18;
	public const int VK_HANJA = 0x19;
	public const int VK_KANJI = 0x19;
	public const int VK_IME_OFF = 0x1A;
	public const int VK_ESCAPE = 0x1B;
	public const int VK_CONVERT = 0x1C;
	public const int VK_NONCONVERT = 0x1D;
	public const int VK_ACCEPT = 0x1E;
	public const int VK_MODECHANGE = 0x1F;
	public const int VK_SPACE = 0x20;
	public const int VK_PRIOR = 0x21;
	public const int VK_NEXT = 0x22;
	public const int VK_END = 0x23;
	public const int VK_HOME = 0x24;
	public const int VK_LEFT = 0x25;
	public const int VK_UP = 0x26;
	public const int VK_RIGHT = 0x27;
	public const int VK_DOWN = 0x28;
	public const int VK_SELECT = 0x29;
	public const int VK_PRINT = 0x2A;
	public const int VK_EXECUTE = 0x2B;
	public const int VK_SNAPSHOT = 0x2C;
	public const int VK_INSERT = 0x2D;
	public const int VK_DELETE = 0x2E;
	public const int VK_HELP = 0x2F;
	public const int VK_LWIN = 0x5B;
	public const int VK_RWIN = 0x5C;
	public const int VK_APPS = 0x5D;
	public const int VK_SLEEP = 0x5F;
	public const int VK_NUMPAD0 = 0x60;
	public const int VK_NUMPAD1 = 0x61;
	public const int VK_NUMPAD2 = 0x62;
	public const int VK_NUMPAD3 = 0x63;
	public const int VK_NUMPAD4 = 0x64;
	public const int VK_NUMPAD5 = 0x65;
	public const int VK_NUMPAD6 = 0x66;
	public const int VK_NUMPAD7 = 0x67;
	public const int VK_NUMPAD8 = 0x68;
	public const int VK_NUMPAD9 = 0x69;
	public const int VK_MULTIPLY = 0x6A;
	public const int VK_ADD = 0x6B;
	public const int VK_SEPARATOR = 0x6C;
	public const int VK_SUBTRACT = 0x6D;
	public const int VK_DECIMAL = 0x6E;
	public const int VK_DIVIDE = 0x6F;
	public const int VK_F1 = 0x70;
	public const int VK_F2 = 0x71;
	public const int VK_F3 = 0x72;
	public const int VK_F4 = 0x73;
	public const int VK_F5 = 0x74;
	public const int VK_F6 = 0x75;
	public const int VK_F7 = 0x76;
	public const int VK_F8 = 0x77;
	public const int VK_F9 = 0x78;
	public const int VK_F10 = 0x79;
	public const int VK_F11 = 0x7A;
	public const int VK_F12 = 0x7B;
	public const int VK_F13 = 0x7C;
	public const int VK_F14 = 0x7D;
	public const int VK_F15 = 0x7E;
	public const int VK_F16 = 0x7F;
	public const int VK_F17 = 0x80;
	public const int VK_F18 = 0x81;
	public const int VK_F19 = 0x82;
	public const int VK_F20 = 0x83;
	public const int VK_F21 = 0x84;
	public const int VK_F22 = 0x85;
	public const int VK_F23 = 0x86;
	public const int VK_F24 = 0x87;
	public const int VK_NAVIGATION_VIEW = 0x88;
	public const int VK_NAVIGATION_MENU = 0x89;
	public const int VK_NAVIGATION_UP = 0x8A;
	public const int VK_NAVIGATION_DOWN = 0x8B;
	public const int VK_NAVIGATION_LEFT = 0x8C;
	public const int VK_NAVIGATION_RIGHT = 0x8D;
	public const int VK_NAVIGATION_ACCEPT = 0x8E;
	public const int VK_NAVIGATION_CANCEL = 0x8F;
	public const int VK_NUMLOCK = 0x90;
	public const int VK_SCROLL = 0x91;
	public const int VK_OEM_NEC_EQUAL = 0x92;
	public const int VK_OEM_FJ_JISHO = 0x92;
	public const int VK_OEM_FJ_MASSHOU = 0x93;
	public const int VK_OEM_FJ_TOUROKU = 0x94;
	public const int VK_OEM_FJ_LOYA = 0x95;
	public const int VK_OEM_FJ_ROYA = 0x96;
	public const int VK_LSHIFT = 0xA0;
	public const int VK_RSHIFT = 0xA1;
	public const int VK_LCONTROL = 0xA2;
	public const int VK_RCONTROL = 0xA3;
	public const int VK_LMENU = 0xA4;
	public const int VK_RMENU = 0xA5;
	public const int VK_BROWSER_BACK = 0xA6;
	public const int VK_BROWSER_FORWARD = 0xA7;
	public const int VK_BROWSER_REFRESH = 0xA8;
	public const int VK_BROWSER_STOP = 0xA9;
	public const int VK_BROWSER_SEARCH = 0xAA;
	public const int VK_BROWSER_FAVORITES = 0xAB;
	public const int VK_BROWSER_HOME = 0xAC;
	public const int VK_VOLUME_MUTE = 0xAD;
	public const int VK_VOLUME_DOWN = 0xAE;
	public const int VK_VOLUME_UP = 0xAF;
	public const int VK_MEDIA_NEXT_TRACK = 0xB0;
	public const int VK_MEDIA_PREV_TRACK = 0xB1;
	public const int VK_MEDIA_STOP = 0xB2;
	public const int VK_MEDIA_PLAY_PAUSE = 0xB3;
	public const int VK_LAUNCH_MAIL = 0xB4;
	public const int VK_LAUNCH_MEDIA_SELECT = 0xB5;
	public const int VK_LAUNCH_APP1 = 0xB6;
	public const int VK_LAUNCH_APP2 = 0xB7;
	public const int VK_OEM_1 = 0xBA;
	public const int VK_OEM_PLUS = 0xBB;
	public const int VK_OEM_COMMA = 0xBC;
	public const int VK_OEM_MINUS = 0xBD;
	public const int VK_OEM_PERIOD = 0xBE;
	public const int VK_OEM_2 = 0xBF;
	public const int VK_OEM_3 = 0xC0;
	public const int VK_GAMEPAD_A = 0xC3;
	public const int VK_GAMEPAD_B = 0xC4;
	public const int VK_GAMEPAD_X = 0xC5;
	public const int VK_GAMEPAD_Y = 0xC6;
	public const int VK_GAMEPAD_RIGHT_SHOULDER = 0xC7;
	public const int VK_GAMEPAD_LEFT_SHOULDER = 0xC8;
	public const int VK_GAMEPAD_LEFT_TRIGGER = 0xC9;
	public const int VK_GAMEPAD_RIGHT_TRIGGER = 0xCA;
	public const int VK_GAMEPAD_DPAD_UP = 0xCB;
	public const int VK_GAMEPAD_DPAD_DOWN = 0xCC;
	public const int VK_GAMEPAD_DPAD_LEFT = 0xCD;
	public const int VK_GAMEPAD_DPAD_RIGHT = 0xCE;
	public const int VK_GAMEPAD_MENU = 0xCF;
	public const int VK_GAMEPAD_VIEW = 0xD0;
	public const int VK_GAMEPAD_LEFT_THUMBSTICK_BUTTON = 0xD1;
	public const int VK_GAMEPAD_RIGHT_THUMBSTICK_BUTTON = 0xD2;
	public const int VK_GAMEPAD_LEFT_THUMBSTICK_UP = 0xD3;
	public const int VK_GAMEPAD_LEFT_THUMBSTICK_DOWN = 0xD4;
	public const int VK_GAMEPAD_LEFT_THUMBSTICK_RIGHT = 0xD5;
	public const int VK_GAMEPAD_LEFT_THUMBSTICK_LEFT = 0xD6;
	public const int VK_GAMEPAD_RIGHT_THUMBSTICK_UP = 0xD7;
	public const int VK_GAMEPAD_RIGHT_THUMBSTICK_DOWN = 0xD8;
	public const int VK_GAMEPAD_RIGHT_THUMBSTICK_RIGHT = 0xD9;
	public const int VK_GAMEPAD_RIGHT_THUMBSTICK_LEFT = 0xDA;
	public const int VK_OEM_4 = 0xDB;
	public const int VK_OEM_5 = 0xDC;
	public const int VK_OEM_6 = 0xDD;
	public const int VK_OEM_7 = 0xDE;
	public const int VK_OEM_8 = 0xDF;
	public const int VK_OEM_AX = 0xE1;
	public const int VK_OEM_102 = 0xE2;
	public const int VK_ICO_HELP = 0xE3;
	public const int VK_ICO_00 = 0xE4;
	public const int VK_PROCESSKEY = 0xE5;
	public const int VK_ICO_CLEAR = 0xE6;
	public const int VK_PACKET = 0xE7;
	public const int VK_OEM_RESET = 0xE9;
	public const int VK_OEM_JUMP = 0xEA;
	public const int VK_OEM_PA1 = 0xEB;
	public const int VK_OEM_PA2 = 0xEC;
	public const int VK_OEM_PA3 = 0xED;
	public const int VK_OEM_WSCTRL = 0xEE;
	public const int VK_OEM_CUSEL = 0xEF;
	public const int VK_OEM_ATTN = 0xF0;
	public const int VK_OEM_FINISH = 0xF1;
	public const int VK_OEM_COPY = 0xF2;
	public const int VK_OEM_AUTO = 0xF3;
	public const int VK_OEM_ENLW = 0xF4;
	public const int VK_OEM_BACKTAB = 0xF5;
	public const int VK_ATTN = 0xF6;
	public const int VK_CRSEL = 0xF7;
	public const int VK_EXSEL = 0xF8;
	public const int VK_EREOF = 0xF9;
	public const int VK_PLAY = 0xFA;
	public const int VK_ZOOM = 0xFB;
	public const int VK_NONAME = 0xFC;
	public const int VK_PA1 = 0xFD;
	public const int VK_OEM_CLEAR = 0xFE;

	/*
	* WM_SIZE message wParam values
	*/
	public const int SIZE_RESTORED = 0;
	public const int SIZE_MINIMIZED = 1;
	public const int SIZE_MAXIMIZED = 2;
	public const int SIZE_MAXSHOW = 3;
	public const int SIZE_MAXHIDE = 4;

	/*
	* WM_NCHITTEST and MOUSEHOOKSTRUCT Mouse Position Codes
	*/

	public const int HTERROR = (-2);
	public const int HTTRANSPARENT = (-1);
	public const int HTNOWHERE = 0;
	public const int HTCLIENT = 1;
	public const int HTCAPTION = 2;
	public const int HTSYSMENU = 3;
	public const int HTGROWBOX = 4;
	public const int HTSIZE = HTGROWBOX;
	public const int HTMENU = 5;
	public const int HTHSCROLL = 6;
	public const int HTVSCROLL = 7;
	public const int HTMINBUTTON = 8;
	public const int HTMAXBUTTON = 9;
	public const int HTLEFT = 10;
	public const int HTRIGHT = 11;
	public const int HTTOP = 12;
	public const int HTTOPLEFT = 13;
	public const int HTTOPRIGHT = 14;
	public const int HTBOTTOM = 15;
	public const int HTBOTTOMLEFT = 16;
	public const int HTBOTTOMRIGHT = 17;
	public const int HTBORDER = 18;
	public const int HTREDUCE = HTMINBUTTON;
	public const int HTZOOM = HTMAXBUTTON;
	public const int HTSIZEFIRST = HTLEFT;
	public const int HTSIZELAST = HTBOTTOMRIGHT;
	public const int HTOBJECT = 19;
	public const int HTCLOSE = 20;
	public const int HTHELP = 21;

	/*
	* MapVirtualKey() uMapType values
	*/
	public const int MAPVK_VK_TO_VSC = 0;
	public const int MAPVK_VSC_TO_VK = 1;
	public const int MAPVK_VK_TO_CHAR = 2;
	public const int MAPVK_VSC_TO_VK_EX = 3;
	public const int MAPVK_VK_TO_VSC_EX = 4;

	/*
	* WM_KEYUP/DOWN/CHAR HIWORD(lParam) flags
	*/

	public const int KF_EXTENDED = 0x0100;
	public const int KF_DLGMODE = 0x0800;
	public const int KF_MENUMODE = 0x1000;
	public const int KF_ALTDOWN = 0x2000;
	public const int KF_REPEAT = 0x4000;
	public const int KF_UP = 0x8000;

	/*
	* SetLayeredWindowAttributes() flags
	*/

	public const int  LWA_COLORKEY = 0x00000001;
	public const int  LWA_ALPHA = 0x00000002;


	/*
	* Predefined Clipboard Formats
	*/
	public const int CF_TEXT = 1;
	public const int CF_BITMAP = 2;
	public const int CF_METAFILEPICT = 3;
	public const int CF_SYLK = 4;
	public const int CF_DIF = 5;
	public const int CF_TIFF = 6;
	public const int CF_OEMTEXT = 7;
	public const int CF_DIB = 8;
	public const int CF_PALETTE = 9;
	public const int CF_PENDATA = 10;
	public const int CF_RIFF = 11;
	public const int CF_WAVE = 12;
	public const int CF_UNICODETEXT = 13;
	public const int CF_ENHMETAFILE = 14;
	
	public const int CF_HDROP = 5;
	public const int CF_LOCALE = 16;
	public const int CF_DIBV5 = 17;
	
	public const int CF_OWNERDISPLAY = 0x0080;
	public const int CF_DSPTEXT = 0x0081;
	public const int CF_DSPBITMAP = 0x0082;
	public const int CF_DSPMETAFILEPICT = 0x0083;
	public const int CF_DSPENHMETAFILE = 0x008E;

	/*
	* Global Memory Flags
	*/
	public const int GMEM_FIXED = 0x0000;
	public const int GMEM_MOVEABLE = 0x0002;
	public const int GMEM_ZEROINIT = 0x0040;
	public const int GHND = GMEM_MOVEABLE | GMEM_ZEROINIT;
	public const int GPTR = GMEM_FIXED | GMEM_ZEROINIT;

	/*
	* Raw Input Flags
	*/
	public const int RIDEV_REMOVE = 0x00000001;
	public const int RIDEV_EXCLUDE =0x00000010;
	public const int RIDEV_PAGEONLY =0x00000020;
	public const int RIDEV_NOLEGACY = 0x00000030;
	public const int RIDEV_INPUTSINK = 0x00000100;
	public const int RIDEV_CAPTUREMOUSE = 0x00000200;  // effective when mouse nolegacy is specified, otherwise it would be an error
	public const int RIDEV_NOHOTKEYS = 0x00000200;  // effective for keyboard.
	public const int RIDEV_APPKEYS = 0x00000400;  // effective for keyboard.
	public const int RIDEV_EXINPUTSINK = 0x00001000;
	public const int RIDEV_DEVNOTIFY = 0x00002000;
	public const int RIDEV_EXMODEMASK = 0x000000F0;
	[Comptime(ConstEval=true)]
	public static int RIDEV_EXMODE(int mode)
	{
		return (mode & RIDEV_EXMODEMASK);
	}

	/*
	* Raw Input Usage Flags
	*/
	public const int HID_USAGE_GENERIC_POINTER = (0x01);
	public const int HID_USAGE_GENERIC_MOUSE = (0x02);
	public const int HID_USAGE_GENERIC_JOYSTICK = (0x04);
	public const int HID_USAGE_GENERIC_GAMEPAD = (0x05);
	public const int HID_USAGE_GENERIC_KEYBOARD = (0x06);
	public const int HID_USAGE_GENERIC_KEYPAD = (0x07);
	public const int HID_USAGE_GENERIC_SYSTEM_CTL = (0x80);

	/*
	* Flags for GetRawInputData
	*/
	public const int RID_INPUT = 0x10000003;
	public const int RID_HEADER = 0x10000005;

	
	/*
	 * Raw Input Device Information
	 */
	public const int RIDI_PREPARSEDDATA = 0x20000005;
	public const int RIDI_DEVICENAME = 0x20000007;  // the return valus is the character length, not the byte size
	public const int RIDI_DEVICEINFO = 0x2000000b;

	/*
	* Type of the raw input
	*/
	public const int RIM_TYPEMOUSE = 0;
	public const int RIM_TYPEKEYBOARD = 1;
	public const int RIM_TYPEHID = 2;
	public const int RIM_TYPEMAX = 2;

	/*
	* Notify icon message
	*/

	public const int NIM_ADD = 0x00000000;
	public const int NIM_MODIFY = 0x00000001;
	public const int NIM_DELETE = 0x00000002;
	public const int NIM_SETFOCUS = 0x00000003;
	public const int NIM_SETVERSION = 0x00000004;

	/*
	* Notify icon flags
	*/

	public const int NIF_MESSAGE =  0x00000001;
	public const int NIF_ICON =     0x00000002;
	public const int NIF_TIP =      0x00000004;
	public const int NIF_STATE =    0x00000008;
	public const int NIF_INFO =     0x00000010;
	public const int NIF_GUID =     0x00000020;
	public const int NIF_REALTIME = 0x00000040;
	public const int NIF_SHOWTIP =  0x00000080;

	/*
	 * Flags for TrackPopupMenu
	 */
	public const int TPM_LEFTBUTTON =  0x0000L;
	public const int TPM_RIGHTBUTTON = 0x0002L;
	public const int TPM_LEFTALIGN =   0x0000L;
	public const int TPM_CENTERALIGN = 0x0004L;
	public const int TPM_RIGHTALIGN =  0x0008L;
	public const int TPM_TOPALIGN =        0x0000L;
	public const int TPM_VCENTERALIGN =    0x0010L;
	public const int TPM_BOTTOMALIGN =     0x0020L;
	public const int TPM_HORIZONTAL =      0x0000L;     /* Horz alignment matters more */
	public const int TPM_VERTICAL =        0x0040L;     /* Vert alignment matters more */
	public const int TPM_NONOTIFY =        0x0080L;     /* Don't send any notification msgs */
	public const int TPM_RETURNCMD =       0x0100L;
	public const int TPM_RECURSE =         0x0001L;
	public const int TPM_HORPOSANIMATION = 0x0400L;
	public const int TPM_HORNEGANIMATION = 0x0800L;
	public const int TPM_VERPOSANIMATION = 0x1000L;
	public const int TPM_VERNEGANIMATION = 0x2000L;
	public const int TPM_NOANIMATION =     0x4000L;
	public const int TPM_LAYOUTRTL =       0x8000L;
	public const int TPM_WORKAREA =        0x10000L;

	/*
	 * Menu flags for Add/Check/EnableMenuItem()
	 */
	public const int MF_CHANGE           = 0x00000080L;
	public const int MF_INSERT           = 0x00000000L;
	public const int MF_APPEND           = 0x00000100L;
	public const int MF_DELETE           = 0x00000200L;
	public const int MF_REMOVE           = 0x00001000L;

	public const int MF_BYCOMMAND        = 0x00000000L;
	public const int MF_BYPOSITION       = 0x00000400L;

	public const int MF_SEPARATOR        = 0x00000800L;

	public const int MF_ENABLED          = 0x00000000L;
	public const int MF_GRAYED           = 0x00000001L;
	public const int MF_DISABLED         = 0x00000002L;

	public const int MF_UNCHECKED        = 0x00000000L;
	public const int MF_CHECKED          = 0x00000008L;
	public const int MF_USECHECKBITMAPS  = 0x00000200L;

	public const int MF_STRING           = 0x00000000L;
	public const int MF_BITMAP           = 0x00000004L;
	public const int MF_OWNERDRAW        = 0x00000100L;

	public const int MF_POPUP            = 0x00000010L;
	public const int MF_MENUBARBREAK     = 0x00000020L;
	public const int MF_MENUBREAK        = 0x00000040L;
	 
	public const int MF_UNHILITE         = 0x00000000L;
	public const int MF_HILITE           = 0x00000080L;

	public const int MF_DEFAULT          = 0x00001000L;
	public const int MF_SYSMENU          = 0x00002000L;
	public const int MF_HELP             = 0x00004000L;
	public const int MF_RIGHTJUSTIFY     = 0x00004000L;

	public const int MF_MOUSESELECT      = 0x00008000L;
	public const int MF_END              = 0x00000080L;  /* Obsolete -- only used by old RES files */

	public const int MFT_STRING          = MF_STRING;
	public const int MFT_BITMAP          = MF_BITMAP;
	public const int MFT_MENUBARBREAK    = MF_MENUBARBREAK;
	public const int MFT_MENUBREAK       = MF_MENUBREAK;
	public const int MFT_OWNERDRAW       = MF_OWNERDRAW;
	public const int MFT_RADIOCHECK      = 0x00000200L;
	public const int MFT_SEPARATOR       = MF_SEPARATOR;
	public const int MFT_RIGHTORDER      = 0x00002000L;
	public const int MFT_RIGHTJUSTIFY    = MF_RIGHTJUSTIFY;

	/* Menu flags for Add/Check/EnableMenuItem() */
	public const int MFS_GRAYED          = 0x00000003L;
	public const int MFS_DISABLED        = MFS_GRAYED;
	public const int MFS_CHECKED         = MF_CHECKED;
	public const int MFS_HILITE          = MF_HILITE;
	public const int MFS_ENABLED         = MF_ENABLED;
	public const int MFS_UNCHECKED       = MF_UNCHECKED;
	public const int MFS_UNHILITE        = MF_UNHILITE;
	public const int MFS_DEFAULT         = MF_DEFAULT;

	/* KEYBDINPUT dwFlags possible values */
	public const int KEYEVENTF_EXTENDEDKEY	= 0x0001;
	public const int KEYEVENTF_KEYUP	= 0x0002;
	public const int KEYEVENTF_SCANCODE	= 0x0008;
	public const int KEYEVENTF_UNICODE	= 0x0004;


}

#endif // BF_PLATFORM_WINDOWS