#if BF_PLATFORM_WINDOWS

using System;
using System.Interop;

namespace FuKeys;

class DeviceManager_Windows : DeviceManager
{
	struct HDEVINFO : Windows.Handle
	{

	}

	[CRepr]
	struct GUID : this(uint32 data, uint16 data2, uint16 data3, uint8[8] data4)
	{
		
	}

	[CRepr]
	struct SP_DEVICE_INTERFACE_DATA
	{
		public c_uint cbSize;
		public GUID InterfaceClassGuid;
		public c_uint Flags;
		public c_uintptr Reserved;
	}

	[CRepr]
	struct SP_DEVICE_INTERFACE_DETAIL_DATA_W
	{
		public c_uint cbSize;
		public c_wchar[1] DevicePath;
	}

	[CRepr]
	struct SP_DEVINFO_DATA
	{
		public c_uint cbSize;
		public GUID ClassGuid;
		public c_uint DevInst;
		public c_uintptr Reserved;
	}

	[CallingConvention(.Stdcall), CLink]
	static extern HDEVINFO SetupDiGetClassDevsW(GUID* ClassGuid, c_wchar* Enumerator, Windows.HWnd  hwndParent, c_uint Flags);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool SetupDiDestroyDeviceInfoList(HDEVINFO DeviceInfoSet);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool SetupDiEnumDeviceInterfaces(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, GUID* InterfaceClassGuid, c_uint MemberIndex, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool SetupDiGetDeviceInterfaceDetailW(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, SP_DEVICE_INTERFACE_DETAIL_DATA_W* DeviceInterfaceDetailData, c_uint DeviceInterfaceDetailDataSize, c_uint* RequiredSize, SP_DEVINFO_DATA* DeviceInfoData);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.Handle GetProcessHeap();

	[CallingConvention(.Stdcall), CLink]
	static extern void* HeapAlloc(Windows.Handle hHeap, c_uint dwFlags, c_size dwBytes);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool HeapFree(Windows.Handle hHeap, c_uint dwFlags, void* lpMem);

	const int HEAP_ZERO_MEMORY = 0x00000008;

	enum ACCESS_MASK : c_uint
	{
		StandardRequired = 0x000F0000,
		#unwarn		
		StandardRead = .ReadControl,
		#unwarn		
		StandardWrite = .ReadControl,
		#unwarn		
		StandardExecute = .ReadControl,

		Delete = 1 << 16,
		ReadControl = 1 << 17,
		WriteDAC = 1 << 18,
		WriteOwner = 1 << 19,
		Synchronize = 1 <<20,

		GenericAll = 1 << 28,
		GenericExecute = 1 << 29,
		GenericWrite = 1 << 30,
		GenericRead = 1 << 31
	}

	enum FILE_SHARE : c_uint
	{
		None = 0,
		Delete = 0x00000004,
		Read = 0x00000001,
		Write = 0x00000002
	}

	enum CREATE_DISPOSITION : c_uint
	{
		CreateAlways = 2,
		CreateNew = 1,
		OpenAlways = 4,
		OpenExisting = 3,
		TruncateExisting = 5
	}

	[CRepr]
	struct SECURITY_ATTRIBUTES
	{
		public c_uint nLength;
		public Windows.SECURITY_DESCRIPTOR* lpSecurityDescriptor;
		public Windows.IntBool bInheritHandle;
	}

	enum FILE_ATTRIBUTE : c_uint
	{
		ReadOnly = 0x00000001,          // The file is read only.
		Hidden = 0x00000002,            // The file is hidden, and thus is not included in an ordinary directory listing.
		System = 0x00000004,            // The file is part of the operating system or is used exclusively by the operating system.
		Directory = 0x00000010,         // The handle that identifies a directory.
		Archive = 0x00000020,           // The file or directory is an archive file or directory. Applications use this attribute to mark files for backup or removal.
		Device = 0x00000040,            // Reserved for system use.
		Normal = 0x00000080,            // The file has no other attributes set. This attribute is valid only when used alone.
		Temporary = 0x00000100,         // The file is being used for temporary storage.
		SparseFile = 0x00000200,        // The file is a sparse file.
		ReparsePoint = 0x00000400,      // The file or directory has an associated reparse point, or the file is a symbolic link.
		Compressed = 0x00000800,        // The file or directory is compressed.
		Offline = 0x00001000,           // The data of the file is not immediately available.
		NotContentIndexed = 0x00002000, // The file or directory is not to be indexed by the content indexing service.
		Encrypted = 0x00004000,         // The file or directory is encrypted.
		IntegrityStream = 0x00008000,   // The file or directory has integrity support.
		Virtual = 0x00010000,           // The file is a virtual file.
		NoScrubData = 0x00020000,       // The file or directory is excluded from the data integrity scan.
		Ea = 0x00040000,                // The file has extended attributes.
		#unwarn
		RecallOnOpen = 0x00040000,      // The file or directory is not fully present locally.
		Pinned = 0x00080000,            // The file or directory is pinned.
		Unpinned = 0x00100000,          // The file or directory is unpinned.
		RecallOnDataAccess = 0x00400000 // The file or directory is recalled on data access.
	}

	enum FILE_FLAGS : c_uint
	{
		WriteThrough = 0x80000000,          // Write operations will not go through any intermediate cache, they will go directly to disk.
		Overlapped = 0x40000000,            // The file can be used for asynchronous I/O.
		NoBuffering = 0x20000000,           // The file will not be cached or buffered in any way.
		RandomAccess = 0x10000000,          // The file is being accessed in random order.
		SequentialScan = 0x08000000,        // The file is being accessed sequentially from beginning to end.
		DeleteOnClose = 0x04000000,         // The file is to be automatically deleted when the last handle to it is closed.
		BackupSemantics = 0x02000000,       // The file is being opened or created for a backup or restore operation.
		PosixSemantics = 0x01000000,        // The file is to be accessed according to POSIX rules.
		OpenReparsePoint = 0x00200000,      // The file is to be opened and a reparse point will not be followed.
		OpenNoRecall = 0x00100000,          // The file data should not be recalled from remote storage.
		FirstPipeInstance = 0x00080000      // The creation of the first instance of a named pipe.
	}


	[CallingConvention(.Stdcall), CLink]
	static extern Windows.Handle CreateFileW(
		c_wchar* lpFileName,
		ACCESS_MASK desiredAccess,
		FILE_SHARE shareMode,
		SECURITY_ATTRIBUTES* lpSecurityAttributes,
		CREATE_DISPOSITION creationDisposition,
		uint32 dwFlagsAndAttributes,
		Windows.Handle hTemplateFile);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool WriteFile(Windows.Handle hFile, void* lpBuffer, c_uint nNumberOfBytesToWrite, c_uint* lpNumberOfBytesWritten, Windows.Overlapped* lpOverlapped);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool ReadFile(Windows.Handle hFile, void* lpBuffer, c_uint nNumberOfBytesToRead, c_uint* lpNumberOfBytesRead, Windows.Overlapped* lpOverlapped);

	[CallingConvention(.Stdcall)]
	function void OVERLAPPED_COMPLETION_ROUTINE(c_uint dwErrorCode, c_uint dwNumberOfBytesTransfered, Windows.Overlapped* lpOverlapped);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool WriteFileEx(Windows.Handle hFile, void* lpBuffer, c_uint nNumberOfBytesToRead, Windows.Overlapped* lpOverlapped, OVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool ReadFileEx(Windows.Handle hFile, void* lpBuffer, c_uint nNumberOfBytesToRead, Windows.Overlapped* lpOverlapped, OVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

	[CallingConvention(.Stdcall), CLink]
	static extern c_uint WaitForSingleObject(Windows.Handle hHandle, c_uint dwMilliseconds);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool GetOverlappedResult(Windows.Handle hFile, Windows.Overlapped* lpOverlapped, c_uint* lpNumberOfBytesTransferred, Windows.IntBool bWait);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.Handle CreateEventW(SECURITY_ATTRIBUTES* lpEventAttributes, Windows.IntBool bManualReset, Windows.IntBool bInitialState, c_wchar* lpName);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool CancelIo(Windows.Handle hFile);

	[CallingConvention(.Stdcall), CLink]
	static extern Windows.IntBool CancelIoEx(Windows.Handle hFile, Windows.Overlapped* lpOverlapped);

	const int WAIT_ABANDONED = 0x00000080L;
	const int WAIT_OBJECT_0 = 0x00000000L;
	const int WAIT_TIMEOUT = 0x00000102L;
	const int WAIT_FAILED = 0xFFFFFFFF;

	struct HIDP_PREPARSED_DATA;

	[CRepr]
	struct HIDP_CAPS
	{
		public c_ushort Usage;
		public c_ushort UsagePage;
		public c_ushort InputReportByteLength;
		public c_ushort OutputReportByteLength;
		public c_ushort FeatureReportByteLength;
		public c_ushort[17] Reserved;
		public c_ushort NumberLinkCollectionNodes;
		public c_ushort NumberInputButtonCaps;
		public c_ushort NumberInputValueCaps;
		public c_ushort NumberInputDataIndices;
		public c_ushort NumberOutputButtonCaps;
		public c_ushort NumberOutputValueCaps;
		public c_ushort NumberOutputDataIndices;
		public c_ushort NumberFeatureButtonCaps;
		public c_ushort NumberFeatureValueCaps;
		public c_ushort NumberFeatureDataIndices;
	}

	const int FACILITY_HID_ERROR_CODE = 0x11;

	[Comptime(ConstEval=true)]
	static int32 HIDP_ERROR_CODES(int32 sev, int32 code) => (sev << 28) | (FACILITY_HID_ERROR_CODE << 16) | code;

	enum HidpStatus : c_int
	{
		case 
		Success = 				HIDP_ERROR_CODES(0x0, 0),
		Null = 					HIDP_ERROR_CODES(0x8, 1),
		InvalidPreparsedData = 	HIDP_ERROR_CODES(0xC, 1),
		InvalidReportType = 	HIDP_ERROR_CODES(0xC, 2),
		InvalidReportLength = 	HIDP_ERROR_CODES(0xC, 3),
		UsageNotFound = 		HIDP_ERROR_CODES(0xC, 4),
		ValueOutOfRange = 		HIDP_ERROR_CODES(0xC, 5),
		BadLogPhyValues = 		HIDP_ERROR_CODES(0xC, 6),
		BufferTooSmall = 		HIDP_ERROR_CODES(0xC, 7),
		InternalError = 		HIDP_ERROR_CODES(0xC, 8),
		I8042TransUnknown = 	HIDP_ERROR_CODES(0xC, 9),
		IncompatibleReportID = 	HIDP_ERROR_CODES(0xC, 0xA),
		NotValueArray = 		HIDP_ERROR_CODES(0xC, 0xB),
		IsValueArray = 			HIDP_ERROR_CODES(0xC, 0xC),
		DataIndexNotFound = 	HIDP_ERROR_CODES(0xC, 0xD),
		DataIndexOutOfRange = 	HIDP_ERROR_CODES(0xC, 0xE),
		ButtonNotPressed = 		HIDP_ERROR_CODES(0xC, 0xF),
		ReportDoesNotExist = 	HIDP_ERROR_CODES(0xC, 0x10),
		NotImplemented = 		HIDP_ERROR_CODES(0xC, 0x20),
		NotButtonArray = 		HIDP_ERROR_CODES(0xC, 0x21);

		public static operator bool (Self value)
		{
			return value >= 0;
		}
	}

	[CallingConvention(.Stdcall), CLink]
	static extern bool HidD_GetPreparsedData(Windows.Handle HidDeviceObject, HIDP_PREPARSED_DATA** PreparsedData);

	[CallingConvention(.Stdcall), CLink]
	static extern bool HidD_FreePreparsedData(HIDP_PREPARSED_DATA* PreparsedData);

	[CallingConvention(.Stdcall), CLink]
	static extern HidpStatus HidP_GetCaps(HIDP_PREPARSED_DATA* PreparsedData, HIDP_CAPS* Capabilities);

	[CallingConvention(.Stdcall), CLink]
	static extern bool HidD_GetProductString(Windows.Handle HidDeviceObject, void* Buffer, c_ulong BufferLength);
	
	[CallingConvention(.Stdcall), CLink]
	static extern bool HidD_GetPhysicalDescriptor(Windows.Handle HidDeviceObject, void* Buffer, c_ulong BufferLength);

	[CallingConvention(.Stdcall), CLink]
	static extern bool HidD_GetNumInputBuffers(Windows.Handle HidDeviceObject, c_ulong* NumberBuffers);

	[CallingConvention(.Stdcall), CLink]
	static extern void HidD_GetHidGuid(GUID* HidGuid);
	
	class WindowsDeviceInfo : DeviceInfo
	{
		append String _devicePath;

		public this(StringView devicePath, uint32 vendorId, uint32 productId, Guid classGuid) : base(vendorId, productId, classGuid)
		{
			_devicePath.Set(devicePath);
		}

		~this()
		{
		}

		[NoDiscard]
		public override Device CreateDevice()
		{
			var handle = CreateFileW(
				_devicePath.ToScopedNativeWChar!(),
				.GenericRead | .GenericWrite,
				.Read | .Write,
				null,
				.OpenExisting,
				FILE_FLAGS.Overlapped.Underlying,
				.NullHandle);


			return new WindowsDevice(handle);
		}
	}

	class WindowsDevice : Device
	{
		Windows.Handle _handle;

		bool _hasError = false;

		public this(Windows.Handle handle)
		{
			_handle = handle;
		}

		~this()
		{
			Windows.CloseHandle(_handle);
		}

		static void ASyncRW_STUB(c_uint a, c_uint b, Windows.Overlapped* o)
		{

		}

		public override Result<int> Read(Span<uint8> buffer, TimeSpan timeout = .MaxValue)
		{
			Windows.Overlapped overlapped = default;
			//overlapped.mHEvent = _handle;
			if (!ReadFileEx(_handle, buffer.Ptr, (.)buffer.Length, &overlapped, => ASyncRW_STUB))
			{
				_hasError = true;
				return .Err;
			}

			uint32 timeoutMS = (.)timeout.TotalMilliseconds;
			if (timeout == .MaxValue)
				timeoutMS = 0xFFFFFFFF; // INFINITE

			let result = WaitForSingleObject(_handle, timeoutMS);
			if (result == WAIT_TIMEOUT)
			{
				CancelIo(_handle);
				return .Err;
			}

			if (result == WAIT_OBJECT_0)
			{
				uint32 readBytes = 0;

				if (GetOverlappedResult(_handle, &overlapped, &readBytes, false))
					return .Ok(readBytes);
			}
			
			return .Err;
		}

		public override Result<int> Write(Span<uint8> buffer, TimeSpan timeout = .MaxValue)
		{
			Windows.Overlapped overlapped = default;
			//overlapped.mHEvent = CreateEventW(null, false, false, null);

			if (!WriteFileEx(_handle, buffer.Ptr, (.)buffer.Length, &overlapped, => ASyncRW_STUB))
			{
				_hasError = true;
				return .Err;
			}

			uint32 timeoutMS = (.)timeout.TotalMilliseconds;
			if (timeout == .MaxValue)
				timeoutMS = 0xFFFFFFFF; // INFINITE

			let result = WaitForSingleObject(_handle, timeoutMS);
			if (result == WAIT_TIMEOUT)
			{
				CancelIo(_handle);
				return .Err;
			}

			if (result == WAIT_OBJECT_0)
			{
				uint32 writtenBytes = 0;

				if (GetOverlappedResult(_handle, &overlapped, &writtenBytes, false))
					return .Ok(writtenBytes);
			}

			return .Err;
		}

		public override bool IsValid => !_hasError;

	}

	Result<uint32> ParseID(StringView input, StringView idName, int startPos, out int endPos)
	{
		endPos = -1;

		var index = input.IndexOf(idName, startPos);
		if (index == -1)
		{
			return .Err;
		}

		index += 4;

		uint32 result = 0;
		while (index < input.Length)
		{
			let c  = input[index];
			if (c.IsDigit)
			{
				result *= 16;
				result += (.)(c - '0');
			}
			else if (c >= 'A' && c <= 'F')
			{
				result *= 16;
				result += 10 + (.)(c - 'A');
			}
			else if (c >= 'a' && c <= 'f')
			{
				result *= 16;
				result += 10 + (.)(c - 'a');
			}
			else if (c == '#' || c == '&')
				break;
			else
				return .Err;

			index++;
		}

		endPos = index;
		return .Ok(result);
	}
		

	Result<Guid> ParseGuid(StringView input, int possiblestart)
	{
		let index = input.IndexOf("#{", possiblestart);
		if (index == -1)
			return .Err;

		let start = index + 2;
		let end = input.IndexOf('}', possiblestart);

		let view = input.Substring(start, end - start);

		Guid guid = default;
		return guid;
	}

	void ReportLastError()
	{
		static int err = 0;
		err = Windows.GetLastError();
	}

	public override void ForEach(EDeviceType type, ForEacHDeviceDelegete forEach, params Span<DeviceFilter> filters)
	{
		const GUID GUID_DEVINTERFACE_USB_DEVICE = .(0xA5DCBF10, 0x6530, 0x11D2, .(0x90, 0x1F, 0x00, 0xC0, 0x4F, 0xB9, 0x51, 0xED));

		GUID hidGuid = default;
		HidD_GetHidGuid(&hidGuid);

		GUID usageGuid;

		switch (type)
		{
		case .USB:
			usageGuid = GUID_DEVINTERFACE_USB_DEVICE;
		case .HID:
			usageGuid = hidGuid;
		}

		const int DIGCF_DEVICEINTERFACE = 0x00000010;
		const int DIGCF_PRESENT = 0x00000002;

		let hDevInfo = SetupDiGetClassDevsW(&usageGuid, null, 0, DIGCF_DEVICEINTERFACE | DIGCF_PRESENT);
		if (hDevInfo == Windows.Handle.InvalidHandle)
			return;

		SP_DEVICE_INTERFACE_DATA intfData = .{
			cbSize = sizeof(SP_DEVICE_INTERFACE_DATA)
		};
		uint32 memberIdx = 0;
		if (!SetupDiEnumDeviceInterfaces(hDevInfo, null, &usageGuid, memberIdx, &intfData))
			return;

		defer SetupDiDestroyDeviceInfoList(hDevInfo);

		String devicePathBuffer = scope .();

		LOOP:
		while (Windows.GetLastError() != Windows.ERROR_NO_MORE_ITEMS)
		{
			MOVE_NEXT:
			do
			{
				SP_DEVINFO_DATA devData = .{
					cbSize = sizeof(SP_DEVINFO_DATA)
				};
				uint32 size = 0;
				SetupDiGetDeviceInterfaceDetailW(hDevInfo, &intfData, null, 0, &size, null);

				let detailData = (SP_DEVICE_INTERFACE_DETAIL_DATA_W*) new:ScopedAlloc! uint8[size]*;

				detailData.cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);

				if (!SetupDiGetDeviceInterfaceDetailW(hDevInfo, &intfData, detailData, size, &size, &devData))
				{
					ReportLastError();
					break MOVE_NEXT;
				}

				devicePathBuffer.Clear();
				devicePathBuffer.Append(&detailData.DevicePath);

				if (ParseID(devicePathBuffer, "vid_", 0, let vidEnd) case .Ok(let vendorid) &&
					ParseID(devicePathBuffer, "pid_", vidEnd, let pidEnd) case .Ok(let productid) &&
					ParseGuid(devicePathBuffer, pidEnd) case .Ok(let guid))
				{
					var handle = CreateFileW(
						&detailData.DevicePath,
						.StandardRead,
						.Read | .Write,
						null,
						.OpenExisting,
						0,
						.NullHandle);

					if (handle == .InvalidHandle && type != .HID)
					{
						ReportLastError();
						break MOVE_NEXT;
					}

					defer Windows.CloseHandle(handle);

					HIDP_CAPS capabilities = default;
					if (type == .HID)
					{
						HIDP_PREPARSED_DATA* preparsedData = null;
						if (!HidD_GetPreparsedData(handle, &preparsedData))
						{
							ReportLastError();
							break MOVE_NEXT;
						}
						defer HidD_FreePreparsedData(preparsedData);
	
						if (!HidP_GetCaps(preparsedData, &capabilities))
						{
							ReportLastError();
							
						}
					}

					CHECK_FILTER:
					do
					{
						if (filters.IsEmpty)
							break CHECK_FILTER;

						for (let f in filters)
						{
							if (f.Match(vendorid, productid, capabilities.UsagePage))
								break CHECK_FILTER;
						}

						break MOVE_NEXT;
					}

					DeviceInfo info = scope WindowsDeviceInfo(devicePathBuffer, vendorid, productid, guid)
					{
						usagePage = capabilities.UsagePage,
						readBufferSize = capabilities.InputReportByteLength,
						writeBufferSize = capabilities.OutputReportByteLength
					};
					
					if (forEach(info) == false)
						break LOOP;
				}
			}
			
			if (!SetupDiEnumDeviceInterfaces(hDevInfo, null, &usageGuid, memberIdx++, &intfData))
				break;
		}

	}
}

#endif // BF_PLATFORM_WINDOWS
