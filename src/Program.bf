using System;
using System.Collections;
using System.Threading;
using System.IO;

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
	const int MAX_CONSECUTIVE_ERRORS = 10;

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
				Thread.Sleep(ERROR_DELAY_MS);
				continue;
			}	

			Hidpp20 driver = scope .(bestDevice.GetDevice(7), bestDevice.GetDevice(20));
			if (driver.Init(bestDevice.isWireless) case .Err)
			{
				Log.Error($"Failed to initialize device. ");
				Thread.Sleep(ERROR_DELAY_MS);
				continue;
			}
			Log.Success(scope $"Device initialized");

			String deviceName = scope .();
			switch (driver.GetDeviceName(deviceName, let supported))
			{
			case .Ok:
				Log.Info(scope $"Device name: {deviceName}");
			case .Err:
				if (supported)
				{
					Log.Error("Failed to retrieve device name");
					Thread.Sleep(ERROR_DELAY_MS);
					continue;
				}
				String name = scope $"UNKNOWN";
				if (Enum.IsDefined<ESupportedProducts>((ESupportedProducts)bestDevice.productId))
				{
					name.Clear();
					((ESupportedProducts)bestDevice.productId).ToString(name);
				}

				Log.Warning(scope $"Device '{name}' doesn't support name retrieval");
			}

			uint8 lastState = 0;
			Hidpp20.EBatteryStatus lastStatus = .Unknown;
			Hidpp20.EBatteryLevel lastLevel = .Unknown;

			int32 consecutiveErrors = 0;
			int32 ignoreAfterDisconnect = 0;

			EVENT_LOOP:
			while (!exitEvent.WaitFor(0) && driver.IsUSBDeviceValid)
			{
				driver.ReadNotifications(.FromMilliseconds(4000));

				if (!driver.DeviceConnected)
				{
					ignoreAfterDisconnect = 1;
					notifications.UpdateTip(scope $"{deviceName}\nDisconnected");
					notifications.UpdateIcon(.ChargingError);
					notifications.CommitChanges();
					Thread.Sleep(2000);
					continue;
				}

				if (driver.GetBatteryStatus() case .Ok((let state, let status, let level)))
				{
					consecutiveErrors = 0;

					if (ignoreAfterDisconnect > 0)
					{
						ignoreAfterDisconnect--;
						if ((state == 1 || (level == .Unknown && state == 0)) && status == .Charging)
							continue;
					}

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
								bool invalidState = (state > 100 || state <= 0) && level != .Unknown;
								
								if ((!invalidState && state > 85) || (invalidState && level == .Full))
									icon = .BatteryFull;
								else if ((!invalidState && state >= 60) || (invalidState && level == .Good))
									icon = .Battery_3_4;
								else if ((!invalidState && state >= 40) || (invalidState && level == .Low))
									icon = .Battery_1_2;
								else if ((!invalidState && state >= 20) || (invalidState && level != .Critical /* Skip 1/4 icon and go to empty */))
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

					if (++consecutiveErrors == MAX_CONSECUTIVE_ERRORS)
					{
						Log.Error("Too many consecutive errors, restarting device handler");
						Thread.Sleep(ERROR_DELAY_MS);
						break EVENT_LOOP;
					}

				}
			}
		}

		Log.Trace("Shutting down device thread");
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

		Directory.CreateDirectory("logs");
		File.Delete("logs/previous.log").IgnoreError();
		File.Move("logs/latest.log", "logs/previous.log").IgnoreError();
		FileStream fs = new .();
		switch (fs.Open("logs/latest.log", .Create, .ReadWrite, .Read))
		{
		case .Err(let err):
			Log.Error(scope $"Failed to open log file ({err})");
			delete fs;

		case .Ok:
			Log.AddCallback(new [=fs](level, time, message, preferredFormat) => {
				fs.Write(preferredFormat).IgnoreError();
				fs.Write(Environment.NewLine).IgnoreError();
				fs.Flush().IgnoreError();
			} ~ {
				delete fs;
			});
		}
		

		Notifications notifications = scope Notifications_Windows();

		if (notifications.Init() case .Err)
		{
			Log.Error("Failed to initialize notifications");
			return 1;
		}
		Log.Success("Initialized notifications");

		WaitEvent exitEvent = scope .();

		let deviceThread = new Thread(new () => RunMouseStuff(exitEvent, notifications));
		deviceThread.Start();

		notifications.Run(scope [?]() => {

			return true;
		});

		exitEvent.Set(true);
		deviceThread.Join();

		Log.Trace("Exiting");

		return 0;
	}
}