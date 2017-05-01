//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Max on 07/04/2017.
//
//

import WatchKit
import WatchConnectivity

extension UIColor{
	
	static var foreground: UIColor {
		return UIColor(red: 0.64, green: 0.08, blue: 0.61, alpha: 1)
	}
}

class VerbRowController: NSObject {
	
	@IBOutlet fileprivate var label: WKInterfaceLabel!
	@IBOutlet fileprivate var bookmarkIndicator: WKInterfaceSeparator!
	
	var verb: Verb! {
		didSet {
			label.setText(verb.infinitif)
			bookmarkIndicator.setHidden(!verb.isBookmarked)
			bookmarkIndicator.setColor(.foreground)
		}
	}
}

class VerbsController: WKInterfaceController {
	
	private var verbs: [Verb]?
	
	@IBOutlet private var table: WKInterfaceTable!
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		
		reloadData()
    }
    
    override func willActivate() {
        super.willActivate()
		
		NotificationCenter.default.addObserver(self, selector: #selector(reloadData),
		                                       name: SharedVerbsDidUpdateNotification, object: nil)
    }
    
    override func didDeactivate() {
        super.didDeactivate()
		
		NotificationCenter.default.removeObserver(self, name: SharedVerbsDidUpdateNotification, object: nil)
    }
	
	@objc private func reloadData() {
		verbs = Verb.sharedVerbs()
		updateUI()
	}
	
	@objc private func updateUI() {
		table.setNumberOfRows(verbs?.count ?? 0, withRowType: "VerbIdentifier")
		
		if let verbs = verbs, verbs.count > 0 {
			var index = 0
			verbs.forEach {
				let row = self.table.rowController(at: index) as! VerbRowController
				row.verb = $0
				index += 1
			}
		}
	}
	
	override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
		return verbs?[rowIndex]
	}
}

class ResultController: WKInterfaceController {
	
	private var verb: Verb!
	
	@IBOutlet private var pastLabel: WKInterfaceLabel!
	@IBOutlet private var participleLabel: WKInterfaceLabel!
	@IBOutlet private var definitionLabel: WKInterfaceLabel!
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		verb = context as! Verb
		updateUI()
	}
	
	private func updateUI() {
		self.setTitle("To \(verb.infinitif)")
		
		pastLabel.setText(verb.past)
		participleLabel.setText(verb.participle)
		definitionLabel.setText(verb.definition)
		
		clearAllMenuItems()
		if (verb.isBookmarked) {
			addMenuItem(withImageNamed: "unbookmark", title: "Unfavorite", action: #selector(unbookmarkAction(sender:)))
		} else {
			addMenuItem(withImageNamed: "bookmark", title: "Favorite", action: #selector(bookmarkAction(sender:)))
		}
		if (verb.hasNote) {
			addMenuItem(withImageNamed: "show-note", title: "Note", action: #selector(showNoteAction(sender:)))
		}
	}
	
	@objc private func bookmarkAction(sender: Any?) {
		sendAction(action: "bookmark") { _ in
			self.verb.isBookmarked = true
			self.updateUI()
		}
	}
	
	@objc private func unbookmarkAction(sender: Any?) {
		sendAction(action: "unbookmark") { _ in
			self.verb.isBookmarked = false
			self.updateUI()
		}
	}
	
	@objc private func showNoteAction(sender: Any?) {
		sendAction(action: "show-note") { (reply: [String : Any]) in
			let note = reply["note"] as! String
			let action = WKAlertAction(title: "Done", style: .cancel) { }
			self.presentAlert(withTitle: "To \(self.verb.infinitif)", message: note,
			                  preferredStyle: .actionSheet, actions: [ action ])
		}
	}
	
	private func sendAction(action: String, replyHandler: (([String : Any]) -> Void)?) {
		let message = ["action" : action, "verb" : verb.infinitif]
		WCSession.default().sendMessage(message, replyHandler: replyHandler) { (error: Error) in
			// @TODO: Show error
			print(error.localizedDescription)
		}
	}
}
