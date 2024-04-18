//
//  Raise3DAPI.swift
//  
//
//  Created by Rick Mann on 2024-04-17.
//

import CryptoKit
import Foundation

/**
	A simple wrapper for the Raise3D local printer HTTP REST API. Note that access
	to the API must be enabled on the printer. See [this article]() for details.
	
	Basic usage:
	
	```swift
	import Raise3DAPI
	
	let api = Raise3DAPI(host: "192.168.0.123:10800", password: "da4536")
	try await api.login()
	
	let systemInfo = try await api.getSystemInformation()
	print("Version: \(systemInfo.version)")
	```
*/

public
class
Raise3DAPI
{
	public
	enum
	Errors : Error
	{
		case loginFailed
		case notAuthorized
		case requestFailed
	}
	
	public
	init(host inHost: String, password inPassword: String)
	{
		self.baseURL = URL(string: "http://\(inHost)/v1/")!
		self.password = inPassword
	}
	
	/**
		Authenticate with the printer using the password set in the printer settings.
	*/
	
	public
	func
	login()
		async
		throws
	{
		let session = URLSession.shared
		
		let ts = Date()
		let ms = Int(round(ts.timeIntervalSince1970 * 1000))
		let signature = calculateSignature(time: ts)
		let url = self.baseURL
					.appending(path: "login")
					.appending(queryItems: [URLQueryItem(name: "sign", value: signature), URLQueryItem(name: "timestamp", value: String(ms))])
		let req = URLRequest(url: url)
		let (data, _) = try await session.data(for: req)
//		print("Response: \((httpResp as! HTTPURLResponse).statusCode)")
		let resp = try JSONDecoder().decode(PrinterResponse<LoginData>.self, from: data)
		guard
			let token = resp.data?.token,
			resp.status == 1
		else
		{
			throw Errors.loginFailed
		}
		
		self.token = token
//		print("Token: \(token)")
	}
	
	func
	calculateSignature(time inTime: Date)
		-> String
	{
		let ms = Int(round(inTime.timeIntervalSince1970 * 1000))
		let stringToSign = "password=\(self.password)&timestamp=\(ms)"
		let sha1 = Insecure.SHA1.hash(data: stringToSign.data(using: .utf8)!)
		let sha1hex = sha1.map { String(format: "%02x", $0) }.joined()
		let md5 = Insecure.MD5.hash(data: sha1hex.data(using: .utf8)!)
		let md5hex = md5.map { String(format: "%02x", $0) }.joined()
		return md5hex
	}
	
	struct
	PrinterResponse<ResponseData : Codable> : Codable
	{
		var status				:	Int
		var data				:	ResponseData?
		var error				:	ResponseError?
	}
	
	struct
	ResponseError : Codable
	{
		var code				:	Int
		var msg					:	String
	}
	
	struct
	LoginData : Codable
	{
		var token				:	String
	}
	
	/**
		Returns basic printer information, including name, model, and software versions.
	*/
	
	public
	func
	getSystemInformation()
		async
		throws
		-> SystemInformation
	{
		let session = URLSession.shared
		
		guard
			let token = self.token
		else
		{
			throw Errors.notAuthorized
		}
		
		let url = self.baseURL
					.appending(path: "printer/system")
					.appending(queryItems: [URLQueryItem(name: "token", value: token)])
		let req = URLRequest(url: url)
		let (data, _) = try await session.data(for: req)
		let resp = try JSONDecoder().decode(PrinterResponse<SystemInformation>.self, from: data)
		guard
			resp.status == 1,
			let data = resp.data
		else
		{
			throw Errors.requestFailed
		}
		
		return data
	}
	
	public
	struct
	SystemInformation : Codable
	{
		public var	apiVersion			:	String
		public var	dateTime			:	String
		public var	firmwareVersion		:	String
		public var	model				:	String
		public var	name				:	String
		public var	serialNumber		:	String
		public var	storageAvailable	:	Int
		public var	update				:	String
		public var	version				:	String
		
		enum
		CodingKeys : String, CodingKey
		{
			case dateTime				=	"date_time"
			case firmwareVersion		=	"firmware_version"
			case model					=	"model"
			case name					=	"machine_name"
			case serialNumber			=	"Serial_number"
			case apiVersion				=	"api_version"
			case storageAvailable		=	"storage_available"
			case update					=	"update"
			case version				=	"version"
		}
	}
	
	/**
		Returns the current running status of the printer. See also ``getJobInformation()``.
	*/
	
	public
	func
	getRunningStatus()
		async
		throws
		-> RunningStatus
	{
		let session = URLSession.shared
		
		guard
			let token = self.token
		else
		{
			throw Errors.notAuthorized
		}
		
		let url = self.baseURL
					.appending(path: "printer/runningstatus")
					.appending(queryItems: [URLQueryItem(name: "token", value: token)])
		let req = URLRequest(url: url)
		let (data, _) = try await session.data(for: req)
		let resp = try JSONDecoder().decode(PrinterResponse<RunningStatus>.self, from: data)
		guard
			resp.status == 1,
			let data = resp.data
		else
		{
			throw Errors.requestFailed
		}
		
		return data
	}
	
	public
	struct
	RunningStatus : Codable
	{
		public var	status				:	Status
		
		public
		enum
		Status : String, Codable
		{
			case idle
			case paused
			case running
			case busy
			case completed
			case error
		}
		
		enum
		CodingKeys : String, CodingKey
		{
			case status					=	"running_status"
		}
	}
	
	/**
		Returns information about the state of fans, feed, and heatbed.
	*/
	
	public
	func
	getBasicInformation()
		async
		throws
		-> BasicInformation
	{
		let session = URLSession.shared
		
		guard
			let token = self.token
		else
		{
			throw Errors.notAuthorized
		}
		
		let url = self.baseURL
					.appending(path: "printer/basic")
					.appending(queryItems: [URLQueryItem(name: "token", value: token)])
		let req = URLRequest(url: url)
		let (data, _) = try await session.data(for: req)
		let resp = try JSONDecoder().decode(PrinterResponse<BasicInformation>.self, from: data)
		guard
			resp.status == 1,
			let data = resp.data
		else
		{
			throw Errors.requestFailed
		}
		
		return data
	}
	
	public
	struct
	BasicInformation : Codable
	{
		public var	fanSpeed			:	Float
		public var	targetFanSpeed		:	Float
		public var	feedRate			:	Float
		public var	targetFeedRate		:	Float
		public var	heatbedTemp			:	Float
		public var	targetHeatbedTemp	:	Float
		
		enum
		CodingKeys : String, CodingKey
		{
			case fanSpeed				=	"fan_cur_speed"
			case targetFanSpeed			=	"fan_tar_speed"
			case feedRate				=	"feed_cur_rate"
			case targetFeedRate			=	"feed_tar_rate"
			case heatbedTemp			=	"heatbed_cur_temp"
			case targetHeatbedTemp		=	"heatbed_tar_temp"
		}
	}
	
	/**
		Returns information about the current job, if any, including status, progress, and elapsed time.
		See also ``getRunningStatus()``.
	*/
	
	public
	func
	getJobInformation()
		async
		throws
		-> JobInformation
	{
		let session = URLSession.shared
		
		guard
			let token = self.token
		else
		{
			throw Errors.notAuthorized
		}
		
		let url = self.baseURL
					.appending(path: "job/currentjob")
					.appending(queryItems: [URLQueryItem(name: "token", value: token)])
		let req = URLRequest(url: url)
		let (data, _) = try await session.data(for: req)
		let resp = try JSONDecoder().decode(PrinterResponse<JobInformation>.self, from: data)
		guard
			resp.status == 1,
			let data = resp.data
		else
		{
			throw Errors.requestFailed
		}
		
		return data
	}
	
	public
	struct
	JobInformation : Codable
	{
		public var	fileName			:	String
		public var	progress			:	Float
		public var	status				:	Status			///	A value in the range [0.0...1.0] representing the print progress.
		public var	elapsedTime			:	Int
		public var	totalTime			:	Int
		
		public
		enum
		Status : String, Codable
		{
			case paused
			case running
			case completed
			case stopped
		}
		
		enum
		CodingKeys : String, CodingKey
		{
			case elapsedTime		=	"printed_time"
			case totalTime			=	"total_time"
			case fileName			=	"file_name"
			case progress			=	"print_progress"
			case status				=	"job_status"
		}
		
		public
		init(from inDecoder: any Decoder)
			throws
		{
			let container = try inDecoder.container(keyedBy: CodingKeys.self)
			
			self.elapsedTime = try container.decode(Int.self, forKey: .elapsedTime)
			self.totalTime = try container.decode(Int.self, forKey: .totalTime)
			self.fileName = try container.decode(String.self, forKey: .fileName)
			self.progress = try container.decode(Float.self, forKey: .progress) / 100.0
			self.status = try container.decode(Raise3DAPI.JobInformation.Status.self, forKey: .status)
		}
		
		public
		func
		encode(to inEncoder: any Encoder)
			throws
		{
			var container = inEncoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(self.elapsedTime, forKey: .elapsedTime)
			try container.encode(self.totalTime, forKey: .totalTime)
			try container.encode(self.fileName, forKey: .fileName)
			try container.encode(self.progress * 100.0, forKey: .progress)
			try container.encode(self.status, forKey: .status)
		}
	}
	
	let	baseURL				:	URL
	let	password			:	String
	var	token				:	String?
}
