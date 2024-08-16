using System;
using System.Collections;
namespace FuKeys;

class Hidpp20
{
	enum EHidppPage : uint16
	{
	    Root = 0x0000,
	    FeatureSet = 0x0001,
	    DeviceInfo = 0x0003,
	    DeviceName = 0x0005,
	    Reset = 0x0020,
	    BatteryLevelStatus = 0x1000,
	    BatteryVoltage = 0x1001,
		UnifiedBattery = 0x1004,
	    LedSWControl = 0x1300,
	    WirelessDeviceStatus = 0x1D4B,
		AdjustableDPI = 0x2201,
	    AngleSnapping = 0x2230,
		SurfaceTuning = 0x2240,
	    AdjustableReportRate = 0x8060,
	    ColorLedEffects = 0x8070,
	    RGBEffects = 0x8071,
	    OnboardProfiles = 0x8100,
	    MouseButtonSpy = 0x8110,
		DFUcontrol2 = 0x00c1,
		LatencyMonitoring = 0x8111,

		HiResWheel = 0x2121,
		OOBState = 0x1805,
		ConfigurableDeviceProps = 0x1806,

		Internal_1 = 0x18a1,
		Internal_EnableHiddfenFeatures = 0x1e00,
		Internal_3 = 0x1e20,
		Internal_4 = 0x1eb0,
		Internal_5 = 0x1850,
		Internal_6 = 0x1801,
		Internal_DeviceReset = 0x1802,
		Internal_8 = 0x1890,
		Internal_9 = 0x1811,
	}

	public enum EReportId : uint8
	{
		Short = 0x10,
		Long = 0x11,
	}

	[Packed, Ordered, Union]
	struct hidpp20_message
	{
		public struct Data
		{
			[Union]
			struct MessageData
			{
				public uint8[16] longParams;
				public uint8[3] shortParams;
			}

			public EReportId report_id;
			public uint8 device_idx;
			public uint8 sub_id;
			public uint8 address;
			public using MessageData message;
		}

		public uint8[20] data;
		public using Data values;
	}

	struct Battery
	{
		public bool batteryPercentage;
		public bool batterLevelStatus;
		public bool rechargable;
		public uint8 supportedLevels1004;
	}

	public enum EBatteryStatus
	{
		Unknown,
		NotCharging, // charging error
		Discharching,
		Charging,
		Full,
	}

	public enum EBatteryLevel
	{
		Unknown,
		Full,
		Good,
		Low,
		Critical
	}

	const uint8 PAGE_ROOT_IDX = 0x00;

	const int c_ShortMessageLength = 7;
	const int c_LongMessageLength = 20;

	DeviceManager.Device _deviceShort;
	DeviceManager.Device _deviceLong;
	uint8 _deviceId;

	Battery battery;

	public struct Hidpp20Feature : this(uint8 index, uint8 type);

	append Dictionary<EHidppPage, Hidpp20Feature> _featuresMap;

	public bool DeviceConnected { get; protected set; }

	Result<Hidpp20Feature> GetFeatureInfo(EHidppPage page)
	{
		if (_featuresMap.TryGetValue(page, let value))
			return .Ok(value);

		return .Err;
	}

	public this(DeviceManager.Device short, DeviceManager.Device long)
	{
		_deviceShort = short;
		_deviceLong = long;
	}

	public bool IsUSBDeviceValid => _deviceShort.IsValid && _deviceLong.IsValid;

	Result<void> WriteShortMessage(hidpp20_message msg)
	{
		var msg;
		let len = Try!(_deviceShort.Write(Span<uint8>((.)&msg, c_ShortMessageLength)));
		if (len != c_ShortMessageLength)
			return .Err;

		return .Ok;
	}


	Result<void> WriteLongMessage(hidpp20_message msg)
	{
		var msg;
		let len = Try!(_deviceLong.Write(Span<uint8>((.)&msg, c_LongMessageLength)));
		if (len != c_LongMessageLength)
			return .Err;

		return .Ok;
	}

	Result<hidpp20_message> ReadMessageShort()
	{
		hidpp20_message msg = default;
		let len = Try!(_deviceShort.Read(.((.)&msg, c_ShortMessageLength), .FromMilliseconds(5000)));

		if (len != c_ShortMessageLength)
			return .Err;

		return msg;
	}

	Result<hidpp20_message> ReadMessageLong()
	{
		hidpp20_message msg = default;
		let len = Try!(_deviceLong.Read(.((.)&msg, c_LongMessageLength), .FromMilliseconds(5000)));

		if (len != c_LongMessageLength)
			return .Err;

		return msg;
	}

	[Warn("Not Implemented")]
	Result<hidpp20_message> ReadMessageAny(out EReportId reportType)
	{
		reportType = default;
		return .Err;
	}

	
	Result<void> EnableConnectionNotification()
	{
		var msg = hidpp20_message{
			report_id = .Short,
			device_idx = 0xFF,
			sub_id = 0x80,
			address = 0x02,
			shortParams = .(0x02,)
		};

		Try!(WriteShortMessage(msg));
		var result = Try!(ReadMessageShort());
		//LogHidMsg(result);

		msg = hidpp20_message{
			report_id = .Short,
			device_idx = 0xFF,
			sub_id = 0x00,
			address = 0x1D,
			shortParams = .(0x01,)
		};

		Try!(WriteShortMessage(msg));
		result  = Try!(ReadMessageShort());
		//LogHidMsg(result);

		msg = hidpp20_message{
			report_id = .Short,
			device_idx = 0xFF,
			sub_id = 0x81,
			address = 0xF1,
			shortParams = .(0x01,)
		};

		Try!(WriteShortMessage(msg));
		result  = Try!(ReadMessageShort());

		msg = hidpp20_message{
			report_id = .Short,
			device_idx = 0xFF,
			sub_id = 0x81,
			address = 0xF1,
			shortParams = .(0x02,)
		};

		Try!(WriteShortMessage(msg));
		result  = Try!(ReadMessageShort());

		msg = hidpp20_message{
			report_id = .Short,
			device_idx = 0xFF,
			sub_id = 0x81,
			address = 0xF1,
			shortParams = .(0x11,)
		};

		Try!(WriteShortMessage(msg));
		result  = Try!(ReadMessageShort());

		return .Ok;
	}

	Result<bool> IsDeviceConnected()
	{
		 let msg = hidpp20_message{
			 report_id = .Long,
			 device_idx = _deviceId,
			 sub_id = 0x00,
			 address = 0x00
		};
		Try!(WriteLongMessage(msg));

		hidpp20_message result = default;
		switch (_deviceLong.Read(.((.)&result, c_LongMessageLength), .FromMilliseconds(1000)))
		{
		case .Ok(let val): return val == c_LongMessageLength;
		case .Err: return false;
		}

	}

	struct Feature : this(uint8 index, uint8 type, uint8 version)
	{
		public this(uint8[3] data) : this(data[0], data[1], data[2])
		{

		}
	}

	Result<(uint8, uint8)> GetProtocolVersion()
	{
		const uint8 CMD_ROOT_GET_PROTOCOL_VERSION = 0x10;

		let msg = hidpp20_message{
		    report_id = .Long,
		    device_idx = _deviceId,
		    sub_id = PAGE_ROOT_IDX,
		    address = CMD_ROOT_GET_PROTOCOL_VERSION
		};
		Try!(WriteLongMessage(msg));
		let result = Try!(ReadMessageLong());
		return .Ok((result.shortParams[0], result.shortParams[1]));
	}

	Result<Feature> RootGetFeature(EHidppPage feature)
	{
		const uint8 CMD_ROOT_GET_FEATURE = 0x00;

		let msg = hidpp20_message{
			report_id = .Long,
			device_idx = _deviceId,
			sub_id = PAGE_ROOT_IDX,
			address = CMD_ROOT_GET_FEATURE,
			shortParams = .((uint8)(feature.Underlying >> 8), (uint8)(feature.Underlying) & 0xFF, 0)
		};
		Try!(WriteLongMessage(msg));
		let result = Try!(ReadMessageLong());
		return Feature(result.shortParams);
	}

	Result<uint8> GetFeatureCount(uint8 reg)
	{
		let msg = hidpp20_message{
			report_id = .Long,
			device_idx = _deviceId,
			sub_id = reg,
			address = 0x00
		};
		Try!(WriteLongMessage(msg));
		let result = Try!(ReadMessageLong());

		return result.shortParams[0];
	}

	Result<(EHidppPage, Hidpp20Feature)> GetFeature(uint8 reg, uint8 featureIndex)
	{
		const uint8 CMD_FEATURE_SET_GET_FEATURE_ID = 0x10;
		let msg = hidpp20_message{
			report_id = .Long,
			device_idx = _deviceId,
			sub_id = reg,
			address = CMD_FEATURE_SET_GET_FEATURE_ID,
			shortParams = .(featureIndex, )
		};
		Try!(WriteLongMessage(msg));
		let result = Try!(ReadMessageLong());

		let page = (EHidppPage)((uint16)result.shortParams[0] << 8 | result.shortParams[1]);
		return (
			page,
			Hidpp20Feature(featureIndex, result.shortParams[2])
		);
	}


	public Result<void> GetDeviceName(String buffer, out bool supported)
	{
		Hidpp20Feature name;
		switch (GetFeatureInfo(.DeviceName) )
		{
			case .Ok(out name):
			{
				supported = true;
			}
			case .Err:
			{
				supported = false;
				return .Err;
			}
		}

		const int CMD_GET_DEVICE_NAME_TYPE_GET_COUNT = 0x01;
		const int CMD_GET_DEVICE_NAME_TYPE_GET_DEVICE_NAME = 0x11;
		#unwarn
		const int CMD_GET_DEVICE_NAME_TYPE_GET_TYPE = 0x21;

		uint8 expectedLength;
		{
			let msg = hidpp20_message{
				report_id = .Long,
				device_idx = _deviceId,
				address = CMD_GET_DEVICE_NAME_TYPE_GET_COUNT,
				sub_id = name.index
			};

			Try!(WriteLongMessage(msg));
			var result = Try!(ReadMessageLong());
			expectedLength = result.longParams[0];
		}

		for (uint8 index = expectedLength; index > 0;)
		{
			var msg = hidpp20_message{
				report_id = .Long,
				device_idx = _deviceId,
				address = CMD_GET_DEVICE_NAME_TYPE_GET_DEVICE_NAME,
				sub_id = name.index,
				longParams = .(expectedLength - index, )
			};

			hidpp20_message result;

			Try!(WriteLongMessage(msg));
			result = Try!(ReadMessageLong());

			let min = Math.Min((uint8)result.longParams.Count, index);
			
			for (let j < min)
			{
				if (result.longParams[j] == '\0')
					break;

				buffer.Append((char8)result.longParams[j]);
			}

			index -= min;
		}

		return .Ok;
	}

	Result<void> GetBatteryCapabilities()
	{
		const int CMD_UNIFIED_BATTERY_GET_CAPABILITIES = 0x00;

		const int FLAG_UNIFIED_BATTERY_FLAGS_RECHARGEABLE = 0x01;
		const int FLAG_UNIFIED_BATTERY_FLAGS_STATE_OF_CHARGE = 0x02;

		if (battery.batterLevelStatus || battery.batteryPercentage)
			return .Ok;

		if (let unified = GetFeatureInfo(.UnifiedBattery))
		{
			let msg = hidpp20_message{
				report_id = .Long,
				device_idx = _deviceId,
				address = CMD_UNIFIED_BATTERY_GET_CAPABILITIES,
				sub_id = unified.index,
			};

			Try!(WriteLongMessage(msg));
			let result = Try!(ReadMessageLong());

			battery.rechargable = result.longParams[1] & FLAG_UNIFIED_BATTERY_FLAGS_RECHARGEABLE != 0;

			if (result.longParams[1] & FLAG_UNIFIED_BATTERY_FLAGS_STATE_OF_CHARGE != 0)
			{
				battery.batteryPercentage = true;
				battery.supportedLevels1004 = 0;
			}
			else
			{
				battery.batterLevelStatus = true;
				battery.supportedLevels1004 = result.longParams[0];
			}

			return .Ok;
		}


		return .Err;
	}

	EBatteryStatus MapBatteryStatus(uint8 chargingStatus, uint8 externalPowerStatus)
	{
		switch (chargingStatus)
		{
		case 0: return .Discharching;
		case 1, 2: return .Charging;
		case 3: return .Full;
		case 4: return .NotCharging;

		default: return .Unknown;
		}
	}

	EBatteryLevel MapBatteryLevel(uint8 level)
	{
		const int FLAG_UNIFIED_BATTERY_LEVEL_CRITICAL = 0x01;
		const int FLAG_UNIFIED_BATTERY_LEVEL_LOW = 0x02;
		const int FLAG_UNIFIED_BATTERY_LEVEL_GOOD = 0x04;
		const int FLAG_UNIFIED_BATTERY_LEVEL_FULL = 0x08;

		var level;
		level &= battery.supportedLevels1004;
		if (level & FLAG_UNIFIED_BATTERY_LEVEL_FULL != 0)
			return .Full;
		else if (level & FLAG_UNIFIED_BATTERY_LEVEL_GOOD != 0)
			return .Good;
		else if (level & FLAG_UNIFIED_BATTERY_LEVEL_LOW != 0)
			return .Low;
		else if (level & FLAG_UNIFIED_BATTERY_LEVEL_CRITICAL != 0)
			return .Critical;

		return .Unknown;
	}



	public Result<(uint8 state, EBatteryStatus status, EBatteryLevel level)> GetBatteryStatus()
	{
		const int CMD_UNIFIED_BATTERY_GET_STATUS = 0x10;


		Try!(GetBatteryCapabilities());

		if (let unified = GetFeatureInfo(.UnifiedBattery))
		{
			let msg = hidpp20_message{
				report_id = .Long,
				device_idx = _deviceId,
				address = CMD_UNIFIED_BATTERY_GET_STATUS,
				sub_id = unified.index,
			};

			Try!(WriteLongMessage(msg));
			let result = Try!(ReadMessageLong());

			let state = result.longParams[0];
			let status = MapBatteryStatus(result.longParams[2], result.longParams[3]);
			let level = MapBatteryLevel(result.longParams[1]);

			return (state, status, level);
		}

		return .Err;
	}

	void LogHidMsg(hidpp20_message msg)
	{
		String data = scope .();

		Span<uint8> view;

		switch (msg.report_id)
		{
		case .Long:
			view = msg.longParams;
		case .Short:
			view = msg.shortParams;
		}

		for (let b in view)
		{
			data.AppendF($"{b:X2} ");
			if ((@b.Index + 1) % 8 == 0)
				data.Append('\n');
		}

		Log.Info(scope
			$"""
			HidMsg:
			id: {msg.report_id}
			deviceId: {msg.device_idx:X2}
			subId: {msg.sub_id:X2}
			address: {msg.address:X2}
			data:
			{data}
			----------------------
			"""
			);
	}

	void HandleNotification(hidpp20_message msg)
	{
		
		if (msg.report_id == .Short &&
			msg.device_idx == _deviceId &&
			msg.sub_id == 0x41)
		{
			// Device disconnect
			if (msg.shortParams[0] & 0x40 != 0)
			{
				DeviceConnected = false;
				Log.Trace("Disconnected");
			}
			else if (msg.shortParams[0] & 0x80 != 0)
			{
				DeviceConnected = true;
				Log.Trace("Connected");
			}
		}
	}

	public void ReadNotifications(TimeSpan timeout)
	{
		hidpp20_message result = default;
		switch (_deviceShort.Read(.((.)&result, c_ShortMessageLength), timeout))
		{
		case .Ok(let val):
			{
				if (val == c_ShortMessageLength)
					HandleNotification(result);
			}
		case .Err:
		}

		switch (_deviceLong.Read(.((.)&result, c_LongMessageLength), timeout))
		{
		case .Ok(let val):
			{
				if (val == c_LongMessageLength)
					HandleNotification(result);
			}
		case .Err:
		}
	}

	public Result<void> Init(bool wireless)
	{
		_deviceId = 0x01;

		if (wireless)
		{
			Try!(EnableConnectionNotification());

			int maxRetries = 8;

			WAIT_CONNECTION:
			do
			{
				LOOP:
				while (--maxRetries > 0)
				{
					if (IsDeviceConnected() case .Ok(let val) && val)
						break WAIT_CONNECTION;
				}

				return .Err;
			}

		}
		DeviceConnected = true;

		List<int> undefinedFeatures = scope .(20);

		if (RootGetFeature(.FeatureSet) case .Ok(let feature))
		{
			//let protocol = GetProtocolVersion();

			var featureCount = Try!(GetFeatureCount(feature.index));
			if (featureCount == 0)
				return .Err;

			featureCount++;

			for (uint8 i in 0..<featureCount)
			{
				if (GetFeature(feature.index, i) case .Ok((let page, let val)))
				{
					if (Enum.IsDefined<EHidppPage>(page))
					{
						if (_featuresMap.TryGetValue(page, let prev))
						{
							Log.Warning(scope $"[HIDPP20] Duplicate feature.\n\tPage: {page}\n\tExisting: {prev.index} {prev.type}\n\tNew: {val.index} {val.type}");
						}

						_featuresMap[page] = val;
					}	
					else
						undefinedFeatures.Add(page.Underlying);
				}
			}
		}

		return .Ok;
	}

}