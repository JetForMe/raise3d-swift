import ArgumentParser
import Foundation

import Raise3DAPI



@main
struct
Raise3DCLI : AsyncParsableCommand
{
	static
	var
	configuration = CommandConfiguration(commandName: "raise3d",
						abstract: "A utility to interact witih Raise3D printers.",
						subcommands: [Info.self, JobStatus.self, Monitor.self, Status.self])
	
	@OptionGroup var options		:	Options
//	@Option(name: [.short, .customLong("addr1")], help: "The printer’s local address.")
//	var addr1						:	String
//
//	@Option(name: [.short, .customLong("password1")], help: "The printer’s password.")
//	var password1					:	String?

	
//	static
//	func
//	main()
//		async
//	{
//		do
//		{
//			var command = try parseAsRoot()
//			
//			if var asyncCommand = command as? any AsyncStateCommand
//			{
//				let password = command.options.password
//				let api = Raise3DAPI(host: command.addr1, password: self.password)
//				try await api.login()
//			
//				try await asyncCommand.run()
//			}
//			else
//			{
//				try command.run()
//			}
//		}
//		
//		catch
//		{
//			exit(withError: error)
//		}
//	}
}

protocol
AsyncStateCommand : AsyncParsableCommand
{
	associatedtype State
	
	func
	run(state: State)
		async
		throws
}

struct
Options : ParsableArguments
{
	@Option(name: [.short, .customLong("addr")], help: "The printer’s local address.")
	var addr						:	String

	@Option(name: [.short, .customLong("password")], help: "The printer’s password.")
	var password					:	String?

}

extension
Raise3DCLI
{
	struct
	JobStatus : AsyncParsableCommand
	{
		static
		var
		configuration = CommandConfiguration(commandName: "job",
							abstract: "Return printer job status.")
		
		@OptionGroup var options		:	Options
		
		mutating
		func
		run()
			async
			throws
		{
			let password = self.options.password ??
			{
				print("Password: ", terminator: "")
				let pw = readLine(strippingNewline: true)
				return pw!
			}()
			
			let api = Raise3DAPI(host: self.options.addr, password: password)
			try await api.login()
			let job = try await api.getJobInformation()
			
			print("File:           \(job.fileName)")
			print("Status:         \(job.status)")
			print("Progress:       \((job.progress).formatted(.percent.precision(.fractionLength(1))))")
			
			let remaining = Duration.seconds(job.totalTime - job.elapsedTime)
			print("Time remaining: \(remaining.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2))))")
			let totalTime = Duration.seconds(job.totalTime)
			print("Total time:     \(totalTime.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2))))")
		}
	}
}

protocol
PrinterCommand : AsyncParsableCommand
{
}

struct
Status : PrinterCommand
{
	static
	var
	configuration = CommandConfiguration(commandName: "status",
						abstract: "Return printer status.")
	
	@OptionGroup var options		:	Options
	
	mutating
	func
	run()
		async
		throws
	{
		let password = self.options.password ??
		{
			print("Password: ", terminator: "")
			let pw = readLine(strippingNewline: true)
			return pw!
		}()
		
		let api = Raise3DAPI(host: self.options.addr, password: password)
		try await api.login()
		let status = try await api.getRunningStatus()
		let basic = try await api.getBasicInformation()
		
		print("Status:              \(status.status)")
		print("Heatbed temp:        \(basic.heatbedTemp)")
		print("Target heatbed temp: \(basic.targetHeatbedTemp)")
		
	}
}

struct
Info : AsyncParsableCommand
{
	static
	var
	configuration = CommandConfiguration(commandName: "info",
						abstract: "Return information about the printer.")
	
	@OptionGroup var options		:	Options
	
	mutating
	func
	run()
		async
		throws
	{
		let password = self.options.password ??
		{
			print("Password: ", terminator: "")
			let pw = readLine(strippingNewline: true)
			return pw!
		}()
		
		let api = Raise3DAPI(host: self.options.addr, password: password)
		try await api.login()
		let info = try await api.getSystemInformation()
		
		print("Name:              \(info.name)")
		print("Model:             \(info.model)")
		print("Version:           \(info.version)")
		let storage = Measurement(value: Double(info.storageAvailable), unit: UnitInformationStorage.bytes)
		print("Storage available: \(storage.formatted(.byteCount(style: .memory)))")
		print("Firmware version:  \(info.firmwareVersion)")
		print("API version:       \(info.apiVersion)")
	}
}

struct
Monitor : AsyncParsableCommand
{
	static
	var
	configuration = CommandConfiguration(commandName: "monitor",
						abstract: "Monitor the selected printer. Control-C to exit")
	
	@OptionGroup var options		:	Options
	
	@Option
	var notify						:	String?
	
	@Option
	var interval					:	Int				=	10
	
	mutating
	func
	run()
		async
		throws
	{
		print("Monitoring printer at address: \(self.options.addr)")
		
		let password = self.options.password ??
		{
			print("Password: ", terminator: "")
			let pw = readLine(strippingNewline: true)
			return pw!
		}()
		
		let api = Raise3DAPI(host: self.options.addr, password: password)
		try await api.login()
		
		//	Get the current state…
		
		let initJob = try await api.getJobInformation()
		self.nextProgressMilestone = nextMilestone(for: initJob.progress)
		
		var progress = initJob.progress
		var progS = progress.formatted(.percent.precision(.fractionLength(1)))
		print("Progress: \(progS) (next milestone: \(self.nextProgressMilestone.formatted(.percent.precision(.fractionLength(1)))))")
		
		//	Poll the printer for updates…
		
		while (true)
		{
			do
			{
				let job = try await api.getJobInformation()
				
				progress = job.progress
				progS = progress.formatted(.percent.precision(.fractionLength(1)))
				
				if progress > 0.0
					&& progress >= self.nextProgressMilestone
					&& job.status == .running
				{
					print("Progress: \(progS) (next milestone: \(self.nextProgressMilestone.formatted(.percent.precision(.fractionLength(1)))))")
					
					if let notifyKey = self.notify
					{
						let remaining = Duration.seconds(job.totalTime - job.elapsedTime)
						let remainS = remaining.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2)))
						try await sendNotification(key: notifyKey, title: "Printer Progress", message: "\(progS), \(remainS) remaining")
					}
				}
				
				self.nextProgressMilestone = nextMilestone(for: progress)
				
				if lastStatus != job.status,
					[.paused, .stopped, .completed].contains(job.status)
				{
					print("Printer has paused or stopped")
					
					if let notifyKey = self.notify
					{
						try await sendNotification(key: notifyKey, title: "Printer has Stopped", message: "Printer is \(job.status)")
					}
				}
				
				self.lastStatus = job.status
				
				try await Task.sleep(for: .seconds(self.interval))
			}
			
			catch
			{
				print("Error monitoring: \(error)")
			}
		}
	}
	
	func
	nextMilestone(for inProg: Float)
		-> Float
	{
		if inProg == 0.0
		{
			return 0.1
		}
		
		let next = ceil(inProg * 10.0) / 10.0
		return next
	}
	
	func
	sendNotification(key inKey: String, title inTitle: String, message inMessage: String? = nil)
		async
		throws
	{
		let url = URL(string: "https://alertzy.app/send")!
		var req = URLRequest(url: url)
		req.httpMethod = "POST"
		
		let title = inTitle.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
		var params = "accountKey=\(inKey)&title=\(title)"
		if let message = inMessage
		{
			let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
			params += "&message=\(encodedMessage)"
		}
		
		req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "content-type")
		req.httpBody = params.data(using: .utf8)
		
		let (_, resp) = try await URLSession.shared.data(for: req)
		let status = (resp as! HTTPURLResponse).statusCode
		print("Notification send status: \(status)")
	}
	
	var	lastStatus				:	Raise3DAPI.JobInformation.Status?
	var	nextProgressMilestone	:	Float									=	0.0
}

//
//@main
//struct RootCommand : AsyncParsableCommand {
//	static
//	var
//	configuration = CommandConfiguration(commandName: "raise3d",
//						abstract: "A utility to interact witih Raise3D printers.",
//						subcommands: [Monitor.self])
//	
//	@Option(help: "The printer’s local address.")
//	var addr: String
//
//	@Option(help: "The printer’s password.")
//	var password: String?
//	
//	mutating
//	func run() async throws -> Raise3DAPI {
//		let password = self.password ?? { /* prompt user for password */ }()
//		let api = Raise3DAPI(host: self.options.addr, password: self.options.password)
//		try await api.login()
//		return api
//	}
//}
//
//struct Monitor : AsyncParsableCommand<Raise3DAPI> {
//	static
//	var configuration = CommandConfiguration(commandName: "monitor",
//												abstract: "Monitor the printer and optionally notify of errors.")
//	
//	@Option(help: "Notify if error.")
//	var notify:	Bool = false
//	
//	mutating
//	func run(state inAPI: Raise3DAPI) async throws
//	{
//		while (true) {
//			let jobInfo = try await inAPI.getJobInfo()
//			
//			if self.notify && jobInfo.status == .error {
//				//	Send notification
//			}
//			
//			Task.sleep(for: .seconds(1))
//		}
//	}
//}


func round<T:BinaryFloatingPoint>(_ value:T, toNearest:T) -> T {
    return round(value / toNearest) * toNearest
}
func round<T:BinaryInteger>(_ value:T, toNearest:T) -> T {
    return T(round(Double(value), toNearest:Double(toNearest)))
}
