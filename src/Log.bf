using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Threading;

namespace FuKeys;

public enum ELogLevel
{
	case Trace,
	Info,
	Success,
	Warning,
	Error,
	Fatal;

	public ConsoleColor ConsoleColor
	{
		[Inline]
		get
		{
			switch (this)
			{
			case .Trace:
				return .Gray;
			case .Info:
				return .White;
			case .Success:
				return .Green;
			case .Warning:
				return .Yellow;
			case .Error:
				return .Red;
			case .Fatal:
				return .Magenta;
			}
		}
	}

	public String Prefix
	{
		[Inline]
		get
		{
			switch (this)
			{
			case .Trace: return "[TRACE]";
			case .Info: return "";
			case .Success: return "[SUCCESS]";
			case .Warning: return "[WARN]";
			case .Error: return "[ERROR]";
			case .Fatal: return "[FATAL]";
			}
		}
	}
}

public delegate void LogCallback(ELogLevel level, DateTime time, StringView message, StringView preferredFormat);

public static class Log
{
	public static ELogLevel LogLevel = .Trace;
	public static ELogLevel LogCallerPathMinLevel = .Error;

	volatile static bool _running;
	private static Monitor _writeMon = new .() ~ delete _;
	private static Thread _cbThread;
	static Queue<LogMessage> _messageQueue = new .() ~ delete _;
	private static WaitEvent _waitEvent;
	private static WaitEvent _workerDoneEvent = new .(false) ~ delete _;

	internal static void Init()
	{
		// This doesn't handle Runtime.FatalError :(
		Runtime.AddErrorHandler(new (stage, error) => {

			if (let fe = error as Runtime.FatalError)
			{
				Log.Error(fe.mError);
			}	

			_workerDoneEvent.WaitFor(1000);
			return .ContinueFailure;
		});
		
		Runtime.Assert(!_running);
		_waitEvent = new .(false);
		_running = true;
		_cbThread = new .(new () =>
			{
				const int DEFAULT_MIN_SIZE = 32;
				LogMessage[] messages = null;
				int count = 0;
				while (Interlocked.Load(ref _running))
				{
					_workerDoneEvent.Reset();

					using (_writeMon.Enter())
					{
						count = _messageQueue.Count;
						if (count > 0 && _callbacks.HasListeners)
						{
							if (messages == null || messages.Count < count)
							{
								delete messages;
								messages = new .[Math.Max(DEFAULT_MIN_SIZE, _messageQueue.Count)];
							}
							_messageQueue.CopyTo(messages);
							_messageQueue.Clear();
						}
					}
					for (let i in 0 ..< count)
					{
						let m = messages[i];
						_callbacks(m.level, m.time, m.message, m.formatedMsg);
						delete m;
					}
					count = 0;

					using (_writeMon.Enter())
					{
						if (_messageQueue.IsEmpty)
						{
							_waitEvent.Reset();
							_workerDoneEvent.Set();
						}
					}

					_waitEvent.WaitFor();
				}

				delete messages;
				delete _waitEvent;
			})..Start();
	}

	internal static void Shutdown()
	{
		Interlocked.Store(ref _running, false);
		_waitEvent.Set();
	}

	private static Event<LogCallback> _callbacks ~ _.Dispose();

	public static void AddCallback(LogCallback cb)
	{
		using (_writeMon.Enter())
			_callbacks.Add(cb);
	}
	public static bool RemoveCallback(LogCallback cb)
	{
		using (_writeMon.Enter())
			return _callbacks.Remove(cb) case .Ok;
	}

	[Inline] public static void Trace(StringView message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Trace, message, CallerPath, CallerName, CallerLine);
	[Inline] public static void Info(StringView message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Info, message, CallerPath, CallerName, CallerLine);
	[Inline] public static void Success(StringView message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Success, message, CallerPath, CallerName, CallerLine);
	[Inline] public static void Warning(StringView message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Warning, message, CallerPath, CallerName, CallerLine);
	[Inline] public static void Error(StringView message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Error, message, CallerPath, CallerName, CallerLine);

	[Inline] public static void Trace(String message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Trace(StringView(message), CallerPath, CallerName, CallerLine);
	[Inline] public static void Info(String message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Info(StringView(message), CallerPath, CallerName, CallerLine);
	[Inline] public static void Success(String message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Success(StringView(message), CallerPath, CallerName, CallerLine);
	[Inline] public static void Warning(String message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Warning(StringView(message), CallerPath, CallerName, CallerLine);
	[Inline] public static void Error(String message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Error(StringView(message), CallerPath, CallerName, CallerLine);

	[Inline] public static void Trace<T>(T value, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Trace, value, CallerPath, CallerName, CallerLine);
	[Inline] public static void Info<T>(T value, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Info, value, CallerPath, CallerName, CallerLine);
	[Inline] public static void Success<T>(T value, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Success, value, CallerPath, CallerName, CallerLine);
	[Inline] public static void Warning<T>(T value, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Warning, value, CallerPath, CallerName, CallerLine);
	[Inline] public static void Error<T>(T value, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
		=> Print(.Error, value, CallerPath, CallerName, CallerLine);

	[NoReturn]
	public static void Fatal(StringView message,  String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
	{
		let msg = scope $"{message}\n{CallerName} ({CallerPath}:{CallerLine})";
		Print(.Fatal, msg, CallerPath, CallerName, CallerLine);
		Internal.FatalError(msg, 1);
	}

	private static void Print<T>(ELogLevel level, T val, String CallerPath, String CallerName, int CallerLine)
	{
		Print(level, StringView(scope $"{val}"), CallerPath, CallerName, CallerLine);
	}

	public static void Print(ELogLevel level, StringView message, String CallerPath = Compiler.CallerFilePath, String CallerName = Compiler.CallerMemberName, int CallerLine = Compiler.CallerLineNum)
	{
		if (level < LogLevel)
			return;

		let time =  DateTime.Now;

		let formattedtime = scope $"[{time.Hour:00}:{time.Minute:00}:{time.Second:00}:{time.Millisecond:000}]";
		let levelPrefix = level.Prefix;

		// If this is ever changed also change the prefix calculation formula to get only the message without any additional garbage (time, level...)
		String line = scope $"{formattedtime}{levelPrefix}: {message}";
#if DEBUG
		if(level >= LogCallerPathMinLevel)
			line.AppendF($"\n\t{CallerPath}:{CallerLine} ({CallerName})");
#endif
#if BF_TEST_BUILD
		Console.WriteLine(line);
		return;
#endif

		let start = formattedtime.Length + levelPrefix.Length + 2; // + 2 because of the chars in prefix ": "

		LogMessage lm = new .(level, time, .((.)CallerLine, CallerPath, CallerName), line, start);
		using (_writeMon.Enter())
		{
			_messageQueue.Add(lm);
		}
		_waitEvent.Set(true);

		if (level >= .Error)
			_workerDoneEvent.WaitFor();
	}

	[Inline]
	public static void Flush()
	{
		_workerDoneEvent.WaitFor();
	}

	struct SourceLocationInfo : this(readonly uint32 line, readonly String file, readonly String name)
	{
	}

	private class LogMessage
	{
		public readonly ELogLevel level;
		public readonly DateTime time;
		public readonly SourceLocationInfo source;
		public readonly StringView message;
		public readonly String formatedMsg ~ delete:append _;

		[AllowAppend]
		public this(ELogLevel level, DateTime time, SourceLocationInfo sourceloc, StringView msg, int msgStart)
		{
			String str = append String(msg);

			this.formatedMsg = str;
			this.message = formatedMsg.Substring(msgStart);
			this.source = sourceloc;
			this.time = time;
			this.level = level;
		}
	}

}