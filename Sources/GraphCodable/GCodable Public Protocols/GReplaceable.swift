//	MIT License
//
//	Copyright (c) 2021-2023 Antonino Ficarra
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

/// A protocol that marks **generic** classes whose **type parameters** are
/// classes that can potentially be replaced or obsoleted.
///
/// If a parameter type is replaced, the specialization of the
/// generic class that uses that parameter type must also be replaced.
///
///	**See the UserGuide**.
///
/// - Note: Only generic classes may need this protocol.
public protocol GReplaceable : AnyObject {
	/// The class that replaces `Self`.
	///
	///	**See the UserGuide**.
	///
	/// - returns: The class that replaces `Self`. Generic classes may
	/// return `Self` if the current specialization is not to be replaced.
	static var replacementType : (AnyObject & GDecodable).Type { get }
}

public extension GReplaceable {
	///	Helper function for implementing `replacementType` in generic classes.
	///
	///	**See the UserGuide**.
	///
	/// - parameter typeParameter: the type parameter to be replaced
	/// - returns: the replaced parameter type, if it exists, otherwise
	/// return `typeParameter`
	static func typeParameterReplacement<S:GDecodable>( for typeParameter:S.Type ) -> GDecodable.Type {
		(typeParameter as? GReplaceable.Type)?.replacementType ?? typeParameter
	}
	
	/// Returns true if this class specialization has been replaced.
	static var isReplacedType : Bool {
		self != replacementType
	}
}
