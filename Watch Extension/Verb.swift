//
//  Verb.swift
//  iVerb
//
//  Created by Max on 07/04/2017.
//
//

import Foundation

class Verb {
	
	struct ParsingError: Error {
		let reason: String
		let description: String
	}
	
	var infinitif: String
	var past: String
	var participle: String
	var definition: String
	
	var isBookmarked: Bool = false
	var hasNote: Bool = false
	
	/// `representation` must be "past|pastParticiple|definition|isFavorite|hasNote"
	init(infinitif: String, representation: String) throws {
		self.infinitif = infinitif
		let comps = representation.components(separatedBy: "|")
		if (comps.count != 5) {
			throw ParsingError(reason: "Missing fields",
			                   description: "must be \"past|pastParticiple|definition|isFavorite|hasNote\"")
		}
		(past, participle, definition) = (comps[0], comps[1], comps[2])
		
		guard let isBookmarked = Int(comps[3]), let hasNote = Int(comps[4]) else {
			throw ParsingError(reason: "Invalid fields format",
			                   description: "\"isFavorite\" and \"hasNote\" must be integer (0 for false, any else for true)")
		}
		(self.isBookmarked, self.hasNote) = (isBookmarked != 0, hasNote != 0)
	}
}

extension Verb {
	
	class func sharedVerbs() -> [Verb]? {
		var verbs: [Verb]?
		if let sharedVerbs = UserDefaults.standard.dictionary(forKey: UserDefaultsWatchSharedVerbsKey) as? [String : String] {
			verbs = sharedVerbs.flatMap { try? Verb(infinitif: $0.key, representation: $0.value) }
		}
		return verbs?.sorted { $0.0.infinitif < $0.1.infinitif }
	}
}
