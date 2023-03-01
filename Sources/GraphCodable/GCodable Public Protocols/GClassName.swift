//
//  File.swift
//  
//
//  Created by Antonino Ficarra on 26/02/23.
//

import Foundation

/// A protocol to disable reference type names.
/// **You should never use it.**
public protocol GClassName : AnyObject {
	/// Encoding reference type name is enabled by default
	///
	/// Return `true` if you don't want encode the reference type name
	var disableClassName : Bool { get }
}
