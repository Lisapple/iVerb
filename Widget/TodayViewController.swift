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
			return addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
		}
	}
}

extension TodayViewController {
	fileprivate var lastUpdated: Date? {
		get {
			return Date(timeIntervalSinceReferenceDate: UserDefaults.standard.double(forKey: "lastUpdated"))
		}
		set {
			if let newValue = newValue {
				UserDefaults.standard.set(newValue.timeIntervalSinceReferenceDate, forKey: "lastUpdated")
			} else {
				UserDefaults.standard.removeObject(forKey: "lastUpdated")
			}
		}
	}
}

class TodayViewController: UIViewController, NCWidgetProviding {
	
	fileprivate let kLastUsedPlaylistKey = "Last Used Playlist"
	fileprivate let kSharedVerbsKey = "Shared Verbs"
	
	fileprivate var infinitif: String?
	fileprivate var tense: String?
	fileprivate var lastUsedPlaylist: String?
	fileprivate var isQuizMode = false
	
	@IBOutlet var label: UILabel?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewDidSelected(_:))))
    }
	
	func viewDidSelected(_ gesture: UIGestureRecognizer) {
		if let infinitif = self.infinitif {
			if let lastUsedPlaylist = self.lastUsedPlaylist, let tense = self.tense, self.isQuizMode {
				self.lastUpdated = nil
				let url = "iverb://quiz/\(lastUsedPlaylist.urlEncode!)/\(infinitif)#\(tense)"
				self.extensionContext?.open(URL(string: url)!, completionHandler: nil)
			} else {
				let url = "iverb://verb#\(infinitif)"
				self.extensionContext?.open(URL(string: url)!, completionHandler: nil)
			}
		}
	}
	
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		
		if ((lastUpdated?.timeIntervalSinceNow ?? 0) < 10 * 60) {
			completionHandler(NCUpdateResult.noData)
			return
		}
		
		var textColor = UIColor.white
		if #available(iOSApplicationExtension 10.0, *) {
			textColor = .black
		}
		
		let sharedDefaults = UserDefaults(suiteName: "group.lisacintosh.iverb")
		guard let dict = sharedDefaults?.dictionary(forKey: kSharedVerbsKey), dict.keys.count > 0 else {
			completionHandler(NCUpdateResult.noData)
			return
		}
		
		let v = arc4random()
		self.isQuizMode = ((v % 2) == 1)
		
		let offset = Int(arc4random() % UInt32(dict.keys.count))
		let index = dict.index(dict.startIndex, offsetBy: offset)
		let (key, value) = dict[index]
		self.infinitif = key
		let comps = (value as! String).components(separatedBy: "|")
		guard (comps.count >= 3) else {
			completionHandler(NCUpdateResult.noData)
			return
		}
		
		var string = "To \(comps[0]), \(comps[1]), \(comps[2])\n"
		
		if (self.isQuizMode) {
			let playlistName = sharedDefaults!.string(forKey: kLastUsedPlaylistKey)
			// Ignore non-user playlist that starts and ends with "__"
			self.lastUsedPlaylist = (playlistName != nil && !playlistName!.hasPrefix("_") && !playlistName!.hasSuffix("_")) ? playlistName : nil
			
			if (self.lastUsedPlaylist != nil) {
				let index = Int(arc4random() % 2)
				self.tense = ["past", "past-participle"][index]
				string = "To \(comps[0]), "
				
				if (self.tense == "past") {
					let placeholder = comps[1].characters.reduce("") { $0.0 + "_" }
					string += "\(placeholder), "
				} else {
					string += "\(comps[1]), "
				}
				
				if (self.tense == "past-participle") {
					string += comps[2].characters.reduce("") { $0.0 + "_" }
				} else {
					string += comps[2]
				}
				string += "\n"
			}
		}
		
		var text = comps.last!
		var attributes: [String : Any]?
		if #available(iOSApplicationExtension 10.0, *) {
			attributes = [ NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17) ]
			text = "\n" + text
		}
		let attrString = NSMutableAttributedString(string: text)
		attrString.insert(NSAttributedString(string: string, attributes: attributes), at: 0)
		label?.attributedText = attrString
		label?.textColor = textColor
		
		lastUpdated = Date()
		
        completionHandler(NCUpdateResult.newData)
    }
	
	func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
		var insets = defaultMarginInsets
		insets.top = 0; insets.bottom = 0
		return insets
	}
}
