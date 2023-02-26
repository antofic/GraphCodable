//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 26/02/23.
//

import Foundation

/// A protocol to disable encoding reference type info.
public protocol GTypeInfo : AnyObject {
	/// Encoding reference type info is enabled by default
	///
	/// Return **true** if you want encoding reference type info
	var disableTypeInfo : Bool { get }
}
