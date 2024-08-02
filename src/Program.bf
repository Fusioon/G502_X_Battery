using System;
using System.Collections;
using System.Threading;

using internal FuKeys;

namespace FuKeys;

class Program
{
	const int LOGITECH_VENDOR_ID = 0x046D;

	enum ESupportedProducts : uint32
	{
		NanoReceiver_Lightspeed_1_3 = 0xC547,
		G502_X_Lightspeed = 0xC098
	}

	const (ESupportedProducts productId, bool wireless)[?] SUPPORTED_PRODUCTS = .(
		(.NanoReceiver_Lightspeed_1_3, true),
		(.G502_X_Lightspeed, false)
	);

	const int ERROR_DELAY_MS = 10000;

	static bool IsSupported(uint32 productId, out bool isWireless)
	{
		for (let sp in SUPPORTED_PRODUCTS)
		{
			if (sp.productId.Underlying == productId)
			{
				isWireless = sp.wireless;
				return true;
			}
		}

		isWireless = ?;
		return false;
	}

	class DeviceData
	{
		public uint32 vendorId;
		public uint32 productId;
		public bool isWireless;

		append List<(int32, DeviceManager.Device)> devices = .(3);

		public this()
		{
		}

		public ~this()
		{
			for (let (_, d) in devices)
				delete d;
		}

		public void AddDevice(int32 bufferSize, DeviceManager.Device device)
		{
			devices.Add((bufferSize, device));
		}

		public DeviceManager.Device GetDevice(int32 bufferSize)
		{
			for (let (buffer, device) in devices)
			{
				if (buffer == bufferSize)
					return device;
			}

			return null;
		}

	}

	static DeviceData GetBestDevice(Span<DeviceData> devices)
	{
		DeviceData bestDevice = null;

		for (let dev in devices)
		{
			if (dev.GetDevice(7) == null || dev.GetDevice(20) == null)
				continue;

			if (bestDevice == null)
			{
				bestDevice = dev;
			}

			if (!dev.isWireless)
			{
				bestDevice = dev;
				break;
			}
		}

		return bestDevice;
	}

	static void RunMouseStuff(WaitEvent exitEvent, Notifications notifications)
	{
		DeviceManager deviceMan = scope DeviceManager_Windows();
		List<DeviceData> foundDevices = scope .(16);

		while (!exitEvent.WaitFor(0))
		{
			defer { ClearAndDeleteItems!(foundDevices); }

			DeviceData GetDeviceData(uint32 vendor, uint32 product, bool wireless)
			{
				for (let d in foundDevices)
				{
					if (d.vendorId == vendor && d.productId == product)
					{
						Runtime.Assert(d.isWireless == wireless);
						return d;
					}
				}

				return foundDevices.Add(.. new .() {
					vendorId = vendor,
					productId = product,
					isWireless = wireless
				});
			}

			deviceMan.ForEach(.HID, scope [?](info) => {

				if (info.writeBufferSize != info.readBufferSize)
					return true;

				if (IsSupported(info.productId, let wireless))
				{
					GetDeviceData(info.vendorId, info.productId, wireless).AddDevice((.)info.readBufferSize, info.CreateDevice());
				}

				return true;
			}, .(LOGITECH_VENDOR_ID, null, 0xFF00));

			if (foundDevices.IsEmpty)
				return;

			let bestDevice = GetBestDevice(foundDevices);
			if (bestDevice == null)
			{
				Log.Error("Failed to find supported device.");
				System.Threading.Thread.Sleep(ERROR_DELAY_MS);
				continue;
			}	

			Hidpp20 driver = scope .(bestDevice.GetDevice(7), bestDevice.GetDevice(20));
			if (driver.Init(bestDevice.isWireless) case .Err)
			{
				Log.Error($"Failed to initialize device. ");
				continue;
			}
			Log.Success(scope $"Device initialized");

			String deviceName = scope .();
			switch (driver.GetDeviceName(deviceName))
			{
			case .Ok:
				Log.Info(scope $"Device name: {deviceName}");
			case .Err:
				Log.Warning("Failed to retrieve device name");
			}

			uint8 lastState = 0;
			Hidpp20.EBatteryStatus lastStatus = .Unknown;
			Hidpp20.EBatteryLevel lastLevel = .Unknown;
			while (!exitEvent.WaitFor(0) && driver.IsConnected)
			{
				driver.ReadNotifications(.FromMilliseconds(4000));

				if (!driver.DeviceConnected)
				{
					Thread.Sleep(1000);
					continue;
				}

				if (driver.GetBatteryStatus() case .Ok((let state, let status, let level)))
				{
					if (state != lastState || status != lastStatus || level != lastLevel)
					{
						lastState = state;
						lastStatus = status;
						lastLevel = level;

						notifications.UpdateTip(scope $"{deviceName}\n{status} | {state}%");

						Notifications_Windows.EIcon icon;
						switch (status)
						{
						case .Charging: icon = .Charging;
						case .NotCharging, .Unknown: icon = .ChargingError;
						case .Full: icon  = .BatteryFull;
						case .Discharching:
							{
								if (state > 85)
									icon = .BatteryFull;
								else if (state >= 60)
									icon = .Battery_3_4;
								else if (state >= 40)
									icon = .Battery_1_2;
								else if (state >= 20)
									icon = .Battery_1_4;
								else
									icon = .BatteryEmpty;
							}
						}

						notifications.UpdateIcon(icon);
						notifications.CommitChanges();
					}
				}
				else
				{
					Log.Error("Failed to retrieve battery status");
				}
			}

		}
	}


	public static int Main(String[] args)
	{
		Log.Init();
		defer Log.Shutdown();

		Log.AddCallback(new (level, time, message, preferredFormat) => {
			let color = Console.ForegroundColor;
			Console.ForegroundColor = level.ConsoleColor;
			Console.WriteLine(preferredFormat);
			Console.ForegroundColor = color;
		});

		Notifications notifications = scope Notifications_Windows();
		WaitEvent exitEvent = scope .();

		if (notifications.Init() case .Err)
		{
			Log.Error("Failed to initialize notifications");
			return 1;
		}

		let deviceThread = new Thread(new () => RunMouseStuff(exitEvent, notifications));
		deviceThread.Start();

		notifications.Run(scope [&]() => {

			return true;
		});

		exitEvent.Set(true);
		deviceThread.Join();

		return 0;
	}
}