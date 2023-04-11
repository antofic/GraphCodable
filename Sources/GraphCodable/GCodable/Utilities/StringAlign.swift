//	Apache License
//	Version 2.0, January 2004
//	http://www.apache.org/licenses/

extension String {
	enum Alignment {
		case left
		case right
	}
	
	func align( _ align: Alignment, length: Int, filler:Character = " " ) -> String {
		guard count < length else {
			// nothing to align
			return self
		}
		var string = String(repeating: filler, count: length - count)
		switch align {
			case .left:
				string.insert(contentsOf: self, at: string.startIndex)
			case .right:
				string.insert(contentsOf: self, at: string.endIndex)
		}
		return string
	}
}
