//
//  Raise3DAPI.swift
//  
//
//  Created by Rick Mann on 2024-04-17.
//

import CryptoKit
import Foundation



class
Raise3DAPI
{
	enum
	Errors : Error
	{
		case loginFailed
		case notAuthorized
		case requestFailed
	}
	
	init(host inHost: String, password inPassword: String)
	{
		self.baseURL = URL(string: "http://\(inHost)/v1/")!
		self.password = inPassword
	}
	
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
		
	func
	getSystemInformation()
		async
		throws
		-> PrinterResponse<SystemInformation>
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
			resp.status == 1
		else
		{
			throw Errors.requestFailed
		}
		
		return resp
	}
	
	struct
	SystemInformation : Codable
	{
		var	apiVersion			:	String
		var	dateTime			:	String
		var	firmwareVersion		:	String
		var	model				:	String
		var	name				:	String
		var	serialNumber		:	String
		var	storageAvailable	:	Int
		var	update				:	String
		var	version				:	String
		
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
		
	func
	getRunningStatus()
		async
		throws
		-> PrinterResponse<RunningStatus>
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
			resp.status == 1
		else
		{
			throw Errors.requestFailed
		}
		
		return resp
	}
	
	struct
	RunningStatus : Codable
	{
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
		
		var	status				:	Status
		
		enum
		CodingKeys : String, CodingKey
		{
			case status					=	"running_status"
		}
	}
		
	func
	getBasicInformation()
		async
		throws
		-> PrinterResponse<BasicInformation>
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
			resp.status == 1
		else
		{
			throw Errors.requestFailed
		}
		
		return resp
	}
	
	struct
	BasicInformation : Codable
	{
		var	fanSpeed			:	Float
		var	targetFanSpeed		:	Float
		var	feedRate			:	Float
		var	targetFeedRate		:	Float
		var	heatbedTemp			:	Float
		var	targetHeatbedTemp	:	Float
		
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
		
	func
	getJobInformation()
		async
		throws
		-> PrinterResponse<JobInformation>
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
			resp.status == 1
		else
		{
			throw Errors.requestFailed
		}
		
		return resp
	}
	
	struct
	JobInformation : Codable
	{
		var	fileName			:	String
		var	progress			:	Float		//	TODO: divide returned value by 100.
		var	status				:	Status
		var	elapsedTime			:	Int
		var	totalTime			:	Int
		
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
	}
	
	let	baseURL				:	URL
	let	password			:	String
	var	token				:	String?
}
