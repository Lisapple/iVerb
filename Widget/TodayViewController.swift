//
//  TodayViewController.swift
//  Widget
//
//  Created by Max on 27/12/15.
//
//

import UIKit
import NotificationCenter

extension String {
	
	var urlEncode: String? {
		get {
			return addingPercentEncoding(withAllowedCharacters: .alphanumerics)
		}
	}
}

extension TodayViewController {
	
	private var LastUpdatedKey: String { return "lastUpdated" }
	fileprivate var lastUpdated: Date? {
		get {
			if let interval = UserDefaults.standard.object(forKey: LastUpdatedKey) as? Double {
				return Date(timeIntervalSinceReferenceDate: interval)
			}
			return nil
		}
		set {
			if let newValue = newValue {
				UserDefaults.standard.set(newValue.timeIntervalSinceReferenceDate, forKey: LastUpdatedKey)
			} else {
				UserDefaults.standard.removeObject(forKey: LastUpdatedKey)
			}
			UserDefaults.standard.synchronize()
		}
	}
}

extension String {
	
	var isUserPlaylist: Bool {
		return !(hasPrefix("_") && hasSuffix("_"))
	}
}

class TodayViewController: UIViewController, NCWidgetProviding {
	
	fileprivate let kLastUsedPlaylistKey = "Last Used Playlist"
	fileprivate let kSharedVerbsKey = "Shared Verbs"
	
	fileprivate var infinitif: String?
	fileprivate var tense: String?
	fileprivate var playlistName: String?
	fileprivate var isQuizMode = false
	fileprivate var needsUpdate = true // Force update for first load
	
	@IBOutlet var label: UILabel?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewDidSelected(_:))))
    }
	
	func viewDidSelected(_ gesture: UIGestureRecognizer) {
		if let infinitif = self.infinitif {
			if let playlistName = self.playlistName, let tense = self.tense, self.isQuizMode, playlistName.isUserPlaylist {
				self.lastUpdated = nil
				let url = "iverb://quiz/\(playlistName.urlEncode!)/\(infinitif)#\(tense)"
				self.extensionContext?.open(URL(string: url)!, completionHandler: nil)
			} else {
				let url = "iverb://verb#\(infinitif)"
				self.extensionContext?.open(URL(string: url)!, completionHandler: nil)
			}
		}
	}
	
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		if let interval = lastUpdated?.timeIntervalSinceNow, abs(interval) < 10 * 60 && !needsUpdate { // Wait at leat 10 minutes to refresh
			completionHandler(.noData)
			return
		}
		
		let sharedDefaults = UserDefaults(suiteName: "group.lisacintosh.iverb")
		guard let dict = sharedDefaults?.dictionary(forKey: kSharedVerbsKey), dict.keys.count > 0 else {
			completionHandler(.noData)
			return
		}
		
		let v = arc4random()
		self.isQuizMode = ((v % 2) == 1)
		
		let offset = Int(arc4random() % UInt32(dict.keys.count))
		let index = dict.index(dict.startIndex, offsetBy: offset)
		let (key, value) = dict[index]
		self.infinitif = key
		let comps = (value as! String).components(separatedBy: "|")
		guard let infinitif = self.infinitif, comps.count >= 2 else {
			// @TODO: Should show an error, format is not valid 
			completionHandler(.noData)
			return
		}
		
		var string = "To \(infinitif), \(comps[0]), \(comps[1])\n"
		
		if (self.isQuizMode) {
			self.playlistName = sharedDefaults!.string(forKey: kLastUsedPlaylistKey)
			if (self.playlistName?.isUserPlaylist == true) {
				let index = Int(arc4random() % 2)
				self.tense = ["past", "past-participle"][index]
				string = "To \(infinitif), "
				
				if (self.tense == "past") {
					let placeholder = comps[0].characters.reduce("") { $0.0 + "_" }
					string += "\(placeholder), "
				} else {
					string += "\(comps[0]), "
				}
				
				if (self.tense == "past-participle") {
					string += comps[1].characters.reduce("") { $0.0 + "_" }
				} else {
					string += comps[1]
				}
				string += "\n"
			}
		}
		
		var text = comps.last!
		let bodyAttributes = [ NSFontAttributeName: UIFont.preferredFont(forTextStyle: .body) ]
		let attrString = NSMutableAttributedString(string: text, attributes: bodyAttributes)
		
		var titleAttributes: [String : Any]?
		if #available(iOSApplicationExtension 10.0, *) {
			titleAttributes = [ NSFontAttributeName: UIFont.preferredFont(forTextStyle: .headline) ]
			text = "\n" + text
		}
		attrString.insert(NSAttributedString(string: string, attributes: titleAttributes), at: 0)
		label?.attributedText = attrString
		
		label?.textColor = .lightText
		if #available(iOSApplicationExtension 10.0, *) {
			label?.textColor = .darkText
		}
		
		lastUpdated = Date()
		needsUpdate = false
		
        completionHandler(.newData)
    }
	
	func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
		var insets = defaultMarginInsets
		insets.top = 0; insets.bottom = 0
		return insets
	}
}
