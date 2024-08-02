using System;

namespace FuKeys;


struct DeviceFilter : this(uint32? vendorId, uint32? productId, uint16? usagePage)
{
	public bool Match(uint32 vendor, uint32 product, uint16 usage)
	{
		if (vendorId.HasValue && vendorId.Value != vendor)
			return false;

		if (productId.HasValue && productId.Value != product)
			return false;

		if (usagePage.HasValue && usagePage.Value != usage)
			return false;

		return true;
	}
}

abstract class DeviceManager
{
	abstract public class DeviceInfo
	{
		public readonly uint32 vendorId;
		public readonly uint32 productId;
		public readonly Guid classGuid;

		public uint16 usagePage;

		public int readBufferSize;
		public int writeBufferSize;

		public this(uint32 vendorId, uint32 productId, Guid classGuid)
		{
			this.vendorId = vendorId;
			this.productId = productId;
			this.classGuid = classGuid;
		}


		[NoDiscard]
		public abstract Device CreateDevice();
	}	

	public abstract class Device
	{
		public abstract Result<int> Read(Span<uint8> buffer, TimeSpan timeout = .MaxValue);
		public abstract Result<int> Write(Span<uint8> buffer, TimeSpan timeout = .MaxValue);
		public abstract bool IsValid { get; }
	}

	public enum EDeviceType
	{
		USB,
		HID
	}

	public delegate bool ForEacHDeviceDelegete(DeviceInfo info);
	public abstract void ForEach(EDeviceType type, ForEacHDeviceDelegete forEach, params Span<DeviceFilter> filters);

}