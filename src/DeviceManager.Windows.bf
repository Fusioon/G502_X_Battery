#if BF_PLATFORM_WINDOWS

using System;
using System.Interop;

namespace FuKeys;

class DeviceManager_Windows : DeviceManager
{
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
