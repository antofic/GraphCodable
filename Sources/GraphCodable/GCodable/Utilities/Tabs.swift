//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 13/04/23.
//

import Foundation

struct Tabs : CustomStringConvertible {
	static let defaultTabs	= "   "
	static let noTabs		= ""
	private var tabs	= ""
	private let count	: Int
	private let tab		: String
	
	init( tabString : String = defaultTabs ) {
		count	= tabString.count
		tab		= tabString
	}

	mutating func enter() {
		tabs.append( tab )
	}

	mutating func exit() {
		tabs.removeLast( count )
	}
	
	var description: String {
		return tabs
	}
}
