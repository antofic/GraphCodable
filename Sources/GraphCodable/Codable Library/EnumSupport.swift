//	MIT License
//
//	Copyright (c) 2021 Antonino Ficarra
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

import Foundation

public extension RawRepresentable where Self : GCodable, Self.RawValue == Bool {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}

public extension RawRepresentable where Self : GCodable, Self.RawValue == Int {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == Int8 {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == Int16 {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == Int32 {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == Int64 {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}

public extension RawRepresentable where Self : GCodable, Self.RawValue == UInt {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == UInt8 {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == UInt16 {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == UInt32 {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == UInt64 {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == Float {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
public extension RawRepresentable where Self : GCodable, Self.RawValue == Double {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}

public extension RawRepresentable where Self : GCodable, Self.RawValue == String {
	func encode(to encoder: GEncoder) throws	{
		try encoder.encode( rawValue )
	}
	init(from decoder: GDecoder) throws			{
		guard let value = Self.init(rawValue: try decoder.decode() ) else {
			throw GCodableError.enumDecodeError
		}
		self = value
	}
}
