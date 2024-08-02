using System;
namespace FuKeys;

abstract class Notifications
{
	protected const String FILE_EXT = ".png";

	protected const uint8[?] ICON_BATTERY_FULL = Compiler.ReadBinary("icons/battery-full" + FILE_EXT);
	protected const uint8[?] ICON_BATTERY_3_4 = Compiler.ReadBinary("icons/battery-three-quarters" + FILE_EXT);
	protected const uint8[?] ICON_BATTERY_1_2 = Compiler.ReadBinary("icons/battery-half" + FILE_EXT);
	protected const uint8[?] ICON_BATTERY_1_4 = Compiler.ReadBinary("icons/battery-quarter" + FILE_EXT);
	protected const uint8[?] ICON_BATTERY_EMPTY = Compiler.ReadBinary("icons/battery-empty" + FILE_EXT);
	protected const uint8[?] ICON_CHARGING = Compiler.ReadBinary("icons/bolt" + FILE_EXT);
	protected const uint8[?] ICON_CHARGING_ERROR = Compiler.ReadBinary("icons/bolt-red" + FILE_EXT);


	public enum EIcon
	{
		BatteryFull,
		Battery_3_4,
		Battery_1_2,
		Battery_1_4,
		BatteryEmpty,
		Charging,
		ChargingError
	}


	public abstract Result<void> Init();
	public abstract Result<void> CommitChanges();
	public abstract void UpdateTip(StringView newTip);
	public abstract void UpdateIcon(EIcon icon);
	public abstract void Run(delegate bool() update);

}