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
	
	var urlEncode: NSString? {
		get {
			return stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())
		}
	}
}

class TodayViewController: UIViewController, NCWidgetProviding {
	
	private let kLastUsedPlaylistKey = "Last Used Playlist";
	private let kSharedVerbsKey = "Shared Verbs";
	
	private var lastUpdated: NSDate?
	private var infinitif: String?
	private var tense: String?
	private var lastUsedPlaylist: String?
	private var isQuizMode = false
	
	@IBOutlet var label: UILabel?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "viewDidSelected:"))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func viewDidSelected(gesture: UIGestureRecognizer) {
		if (self.infinitif != nil) {
			if (self.isQuizMode && self.lastUsedPlaylist != nil && self.tense != nil) {
				self.lastUpdated = nil
				let url = "iverb://quiz/\(self.lastUsedPlaylist!.urlEncode!)/\(self.infinitif!)#\(self.tense!)"
				self.extensionContext?.openURL(NSURL(string: url)!, completionHandler: nil)
			} else {
				let url = "iverb://verb#\(self.infinitif!)"
				self.extensionContext?.openURL(NSURL(string: url)!, completionHandler: nil)
			}
		}
	}
	
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
		
		if (lastUpdated != nil && lastUpdated!.timeIntervalSinceNow < 10 * 60) {
			completionHandler(NCUpdateResult.NoData)
		}
		
		srand(UInt32(time(nil)))
		let v = rand()
		self.isQuizMode = ((v % 2) == 1)
		
		let sharedDefaults = NSUserDefaults(suiteName: "group.lisacintosh.iverb")
		let dict = sharedDefaults?.dictionaryForKey(kSharedVerbsKey)
		let index = dict?.startIndex.advancedBy(Int(rand() % Int32(dict!.keys.count)))
		let (key, value) = dict![index!]
		self.infinitif = key
		let comps = (value as! String).componentsSeparatedByString("|")
		
		var string = "To \(comps[0]), \(comps[1]), \(comps[2])\n"
		
		if (self.isQuizMode) {
			let playlistName = sharedDefaults?.stringForKey(kLastUsedPlaylistKey)
			// Ignore non-user playlist that starts and ends with "__"
			self.lastUsedPlaylist = (playlistName != nil && !playlistName!.hasPrefix("_") && !playlistName!.hasSuffix("_")) ? playlistName : nil
			
			if (self.lastUsedPlaylist != nil) {
				let index = Int(rand() % 2)
				self.tense = [ "past", "past-participle" ][index]
				string = "To \(comps[0]), "
				
				if (self.tense == "past") {
					let placeholder = [String](count: comps[1].lengthOfBytesUsingEncoding(NSUTF8StringEncoding), repeatedValue: "_").joinWithSeparator("")
					string += "\(placeholder), "
				} else {
					string += "\(comps[1]), "
				}
				
				if (self.tense == "past-participle") {
					string += [String](count: comps[2].lengthOfBytesUsingEncoding(NSUTF8StringEncoding), repeatedValue: "_").joinWithSeparator("")
				} else {
					string += "\(comps[2])"
				}
				string += "\n"
			}
		}
		
		let attributes = [ NSForegroundColorAttributeName : UIColor.whiteColor() ]
		let attrString = NSMutableAttributedString(string: comps.last!)
		attrString.insertAttributedString(NSAttributedString(string: string, attributes: attributes), atIndex: 0)
		label?.attributedText = attrString
		
		lastUpdated = NSDate()
		
        completionHandler(NCUpdateResult.NewData)
    }
	
	func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
		var insets = defaultMarginInsets
		insets.top = 0; insets.bottom = 0
		return insets
	}
}
