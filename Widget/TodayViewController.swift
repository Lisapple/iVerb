//
//  TodayViewController.swift
//  Widget
//
//  Created by Max on 27/12/15.
//
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
	
	private var infinitif: String?
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
			self.extensionContext?.openURL(NSURL(string: "iverb://verb#\(self.infinitif!)")!, completionHandler: nil)
		}
	}
	
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
		
		srand(UInt32(time(nil)))
		
		let sharedDefaults = NSUserDefaults(suiteName: "group.lisacintosh.iverb")
		let dict = sharedDefaults?.dictionaryForKey("Shared Verbs")
		let index = dict?.startIndex.advancedBy(Int(rand() % Int32(dict!.keys.count)))
		let (key, value) = dict![index!]
		self.infinitif = key
		let comps = (value as! String).componentsSeparatedByString("|")
		
		let attrString = NSMutableAttributedString(string: comps.last!)
		
		let attributes = [ NSForegroundColorAttributeName : UIColor.whiteColor() ]
		let string = "To \(comps[0]), \(comps[1]), \(comps[2])\n"
		attrString.insertAttributedString(NSAttributedString(string: string, attributes: attributes), atIndex: 0)
		
		label?.attributedText = attrString

        completionHandler(NCUpdateResult.NewData)
    }
	
	func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
		var insets = defaultMarginInsets
		insets.top = 0; insets.bottom = 0
		return insets
	}
}
