//
//  MainViewController.swift
//  kCalendarCopy
//
//  Created by Ken Polleck on 5/7/22.
//

import UIKit
import EventKitUI
import EventKit
import FSCalendar


// Overall outline of this code:
// 1. Connects to storyboard
// 2. Calls setupCalendarView of MainCalendarViewExtension to set appearance of calendar
// 3. Loads default calendars
// 4. Handles changes to datePickers
// 5. Segues when clickedOnDate
// 6. Updates highlighted dates on calendar upon changes (to time or text)

// class MainViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, EKCalendarChooserDelegate  {
    
class
MainViewController: UIViewController, UITextFieldDelegate  {
    
    enum Modes {case search, toggle, sync}
    
    let defaults = UserDefaults.standard
    // calendarIDArray
    
    // FSCalendar and related properties for the two calendars I am using
    let calendarManager = EventsCalendarManager()
    var calendarArray = [EKCalendar?]() // Currently using only calendarArray[0] and calendarArray[1]
    var calendarList: [String] = ["Choose Calendar 1", "Choose Calendar 2"]
    var calendarColor: [UIColor] = [.gray, .gray]
    var calendarValid: [Bool] = [false, false]
    var calendarMatches: [Int] = [0,0]
    
    // eventDates are the dates (date only; no time) of matching events for each calendar to display calendar
    var eventDates: [[Date]] = [[Date("2022-05-01")],[Date("2022-05-01")]] // just to have something in array
    // eventStrings are the events' info concatentated together
    var eventStrings: [[String]] = [[""],[""]]
    // eventsSynced are flags which show if an event is already synced
    var eventsSynced: [[Bool]] = [[false],[false]]
    var eventsSyncedCount = 0
    
    // defaults
    var selectedCalendarRow = 0
    var selectedDate = Date()
    var displayedMonth = Date().startOfMonth()
    
    var calendarView = FSCalendar()
    
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var calendarArea: UIView!
    @IBOutlet weak var calendarTableView: UITableView!
    @IBOutlet weak var modeControl: UISegmentedControl!
    @IBOutlet weak var searchFieldLabel: UILabel!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var startPicker: UIDatePicker!
    @IBOutlet weak var endPicker: UIDatePicker!
    @IBOutlet weak var matchStartSwitch: UISwitch!
    @IBOutlet weak var matchEndSwitch: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var actOnCalendarLabel: UILabel!
    @IBOutlet weak var syncButton: UIButton!
    
    var matchTitleExact: Bool = false
    // var matchStart: Bool = false // use setting of switch when necessary instead
    // var matchEnd: Bool = false
    var matchStartTime = "8:00"
    var matchEndTime = "20:00"
    var monthName = ""
    var mode:Modes = .search
    
    var statusHistory = ""
    
    var actOnCalendarSwitches:[UISwitch] = []
    var actOnCalendar = -1 // -1 is act on NONE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateStatus("Starting...")
        statusLabel.isUserInteractionEnabled = true
        
        //self.calendarTableView.register(UITableViewCell.self, forCellReuseIdentifier: "calendarListTableCell")
        //self.calendarTableView.register(UINib(nibName: "calendarListTableCell", bundle: nil), forCellReuseIdentifier: "calendarListTableCell")
        // Delegate to change calendar colors
        calendarView.delegate = self
        
        // Text Field Delegates (to dismiss the keyboare after enter)
        searchField.delegate = self
        
        // Delegate to create and process clicks on the calendarTableView
        calendarTableView.delegate = self
        calendarTableView.dataSource = self
        //self.calendarTableView.register(CalendarListTableCell.self, forCellReuseIdentifier: "cell")  // seems to be required for cell to be custom class
        
        setupCalendarView()

        searchField.text = ""
        
        // default defaults
        let defaultCalendarID = calendarManager.eventStore.defaultCalendarForNewEvents!.calendarIdentifier
        
        // Pre-load something into calendar arrays
        calendarArray.append(nil)
        calendarArray.append(nil)
        calendarList = ["Choose Calendar 1", "Choose Calendar 2"]
        calendarColor = [.gray, .gray]
        calendarValid = [false, false]
        
        // Set selected calendars from defaults (storing just the calendar IDs)
        var calendarIDArray = defaults.object(forKey:"calendarIDArray") as? [String] ?? [String]()
        if calendarIDArray.count == 0 { // if not saved, default both calendars to default
            calendarIDArray = [defaultCalendarID,defaultCalendarID]
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showStatusHistory(tapGestureRecognizer:)))
        statusLabel.addGestureRecognizer(tapGesture)
        
        if calendarIDArray.count > 0 && calendarIDArray[0] != "" {
            calendarArray[0] = calendarManager.eventStore.calendar(withIdentifier: calendarIDArray[0])
            if let oneEKCalendar:EKCalendar = calendarArray[0] {
                calendarList[0] = oneEKCalendar.title
                calendarColor[0] = UIColor(cgColor: calendarArray[0]!.cgColor)
                calendarValid[0] = true
            }
        }
        if calendarIDArray.count > 1 && calendarIDArray[1] != "" {
            calendarArray[1] = calendarManager.eventStore.calendar(withIdentifier: calendarIDArray[1])
            if let oneEKCalendar:EKCalendar = calendarArray[1] {
                calendarList[1] = oneEKCalendar.title
                calendarColor[1] = UIColor(cgColor: calendarArray[1]!.cgColor)
                calendarValid[1] = true
            }
        }
        
        startPicker.date = Date(time: matchStartTime)
        endPicker.date = Date(time: matchEndTime)
        startPicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        endPicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        matchStartSwitch.setOn(false, animated: false)
        matchEndSwitch.setOn(false, animated: false)
        
        syncButton.titleLabel?.numberOfLines = 0; // Dynamic number of lines
        syncButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping;
        syncButton.titleLabel?.textAlignment = .center
        
        let month = Calendar.current.component(.month, from: displayedMonth)
        monthName = DateFormatter().monthSymbols[month - 1].capitalized
        
        // call the 'keyboardWillShow' function when the view controller receive the notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
          
        // call the 'keyboardWillHide' function when the view controlelr receive notification that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setUIFeatures()
    }
    
    // Changing the time to match (or add) events
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        
        // Create date formatter
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let selectedTime: String = dateFormatter.string(from: sender.date)
        
        // print("Selected value \(selectedTime)")
        if sender == startPicker {
            matchStartTime = selectedTime
        }
        
        if sender == endPicker {
            matchEndTime = selectedTime
        }
        
        self.view.endEditing(true)
        
        updateEventDates()
    }
    
    @objc func cancelDatePicker() {
        self.view.endEditing(true)
    }
    
    // *** SEGUE PROCESSING ***

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        updateLog("Segue to \(segue.identifier!)")

        if (segue.identifier == "clickedOnDate") {
            if let destinationVC = segue.destination as? EventViewController {
                destinationVC.mainVC = self
                // destinationVC.calendarArray = self.calendarArray
            }
            updateEventDates()
        }
        if (segue.identifier == "showStatusHistorySegue") {
            if let destinationVC = segue.destination as? StatusHistoryViewController {
                destinationVC.mainVC = self
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func updateEventDates() { // get dates from both calendars
        updateLog("updateEventDates()")
        updateEventDates(0)
        updateEventDates(1)
        if mode == .sync {
            markAlreadySynced()
        }
        calendarTableView.reloadData()
        calendarView.reloadData()
    }

    func updateEventDates(_ calendarIndex: Int) {
        var matchingEvents = [EKEvent]()
        
        if !calendarValid[calendarIndex] { return }
            
        guard let oneCalendar = calendarArray[calendarIndex] else {
            return
        }
        
        let calendarsToSearch : [EKCalendar] = [oneCalendar]
        
        // Check possible range of -7 to +42 days from start of displayed month
        // let predicate = calendarManager.eventStore.predicateForEvents(withStart: Calendar.current.date(byAdding: .day, value: -7, to: displayedMonth)!, end: Calendar.current.date(byAdding: .day, value: 42, to: displayedMonth)!, calendars: calendarsToSearch)
        
        // CHANGE:  Now just current month
        
        let predicate = calendarManager.eventStore.predicateForEvents(withStart: displayedMonth.startOfMonth(), end: displayedMonth.endOfMonth(), calendars: calendarsToSearch)
        let allEventsInMonth = calendarManager.eventStore.events(matching: predicate)
        updateLog("\(allEventsInMonth.count) events in month found.")
        updateLog("Looking to match '\(String(describing: searchField.text!))' on Calendar \(calendarIndex)")

        var matchStart = true
        if mode == .search && !matchStartSwitch.isOn { matchStart = false }
        var matchEnd = true
        if mode == .search && !matchEndSwitch.isOn { matchEnd = false }
        
        matchingEvents.removeAll()
        for e in allEventsInMonth {
            let eventTitle = e.title.replacingOccurrences(of: "\\", with: "")
            // *TODO* Above is probably not the best way to deal with escape character from calendar entry
            
            // "continue" here means "skip the rest of iteration"...that is, skip adding it as a matching event
            if (eventTitle != searchField.text && matchTitleExact) { continue }
            if !(eventTitle.lowercased().contains(searchField.text!.lowercased())) { continue }
            if (matchStart && !e.startDate.hasSameTime(stringHHMMToDate(matchStartTime))) { continue }
            if (matchEnd && !e.endDate.hasSameTime(stringHHMMToDate(matchEndTime))) { continue }
            // OK, it matches
            matchingEvents.append(e)
        }
        
        eventDates[calendarIndex].removeAll()
        eventStrings[calendarIndex].removeAll()
        for event in matchingEvents {
            eventDates[calendarIndex].append(event.startDate.stripTime()) // save eventDates to display calendar
            eventStrings[calendarIndex].append(event.title+event.startDate.asString()+event.endDate.asString())
        }
        updateLog("\(matchingEvents.count) matching events found for calendar \(calendarIndex).")
        calendarMatches[calendarIndex] = matchingEvents.count
    }
    
    func markAlreadySynced() {
        eventsSynced[0].removeAll()
        eventsSynced[1].removeAll()
        eventsSyncedCount = 0
        
        // Create parallel "eventsSynced" arrays
        for _ in eventStrings[0] {
            eventsSynced[0].append(false)
        }
        for _ in eventStrings[1] {
            eventsSynced[1].append(false)
        }
        
        if (eventStrings[0].count == 0 || eventStrings[1].count == 0) { // No match for at least one calendar
            return
        }
        
        for i in 0...eventStrings[0].count - 1 {
            for j in 0...eventStrings[1].count - 1 {
                if eventStrings[0][i] == eventStrings[1][j] {
                    eventsSynced[0][i] = true
                    eventsSynced[1][j] = true
                    eventsSyncedCount += 1
                    updateLog("Already synced: \(eventStrings[0][i])")
                }
            }
        }
    }
    
    @IBAction func modeChange(_ sender: Any) {
        switch modeControl.selectedSegmentIndex {
        case 0: mode = .search
        case 1: mode = .toggle
        case 2: mode = .sync
        default: break
        }
        setUIFeatures()
        updateEventDates()
    }
    
    func setUIFeatures() {
        switch mode {
        case .search:
            updateStatus("Now in search mode.")
            modeLabel.text = "Select a date to see day\'s events"
            modeLabel.backgroundColor = UIColor.systemBlue
            searchFieldLabel.text = "Search for (partial text match):"
            
            matchTitleExact = false
            matchStartSwitch.isHidden = false
            matchEndSwitch.isHidden = false
            actOnCalendarLabel.isHidden = true
            actOnCalendarSwitches[0].isHidden = true
            actOnCalendarSwitches[1].isHidden = true
            
            searchFieldLabel.isHidden = false
            searchField.isHidden = false
            startPicker.isHidden = false
            endPicker.isHidden = false
            
            syncButton.isHidden = true
            
        case .toggle:
            updateStatus("Now in toggle mode.")
            if actOnCalendar != -1 {
                modeLabel.text = "Select a date to toggle event on calendar"
                modeLabel.backgroundColor = UIColor.red
            } else {
                modeLabel.text = "Select a date to see day\'s events"
                modeLabel.backgroundColor = UIColor.systemBlue
            }
            searchFieldLabel.text = "Update with (exact text match):"
            
            matchTitleExact = true
            matchStartSwitch.isHidden = true
            matchEndSwitch.isHidden = true
            actOnCalendarLabel.isHidden = false
            actOnCalendarSwitches[0].isHidden = false
            actOnCalendarSwitches[1].isHidden = false
            
            searchFieldLabel.isHidden = false
            searchField.isHidden = false
            startPicker.isHidden = false
            endPicker.isHidden = false
            
            syncButton.isHidden = true
            
            switch actOnCalendar {
            case -1:
                self.actOnCalendarSwitches[0].setOn(false, animated: false)
                self.actOnCalendarSwitches[1].setOn(false, animated: false)
            case 0:
                self.actOnCalendarSwitches[0].setOn(true, animated: false)
                self.actOnCalendarSwitches[1].setOn(false, animated: false)
            case 1:
                self.actOnCalendarSwitches[0].setOn(false, animated: false)
                self.actOnCalendarSwitches[1].setOn(true, animated: false)
            default:
                break
            }

        case .sync:
            updateStatus("Now in sync mode.")
            
            if actOnCalendar != -1 {
                modeLabel.text = "Press Sync button to update target calendar"
                modeLabel.backgroundColor = UIColor.systemPurple
            } else {
                modeLabel.text = "Select a date to see day\'s events"
                modeLabel.backgroundColor = UIColor.systemBlue
            }
            searchFieldLabel.text = "Sync with (exact text match):"
            
            matchTitleExact = true
            matchStartSwitch.isHidden = true
            matchEndSwitch.isHidden = true
            actOnCalendarLabel.isHidden = false
            actOnCalendarSwitches[0].isHidden = false
            actOnCalendarSwitches[1].isHidden = false
            
            searchFieldLabel.isHidden = false
            searchField.isHidden = false
            startPicker.isHidden = false
            endPicker.isHidden = false
            
            if actOnCalendar == -1 {
                syncButton.isHidden = true
                syncButton.setTitle("Sync", for: .normal)
            } else {
                syncButton.isHidden = false
                let otherCalendar = 1-actOnCalendar
                syncButton.setTitle("Sync \(calendarMatches[otherCalendar]-eventsSyncedCount) items to \(calendarList[actOnCalendar]) for \(monthName)", for: .normal)
            }
            
            switch actOnCalendar {
            case -1:
                self.actOnCalendarSwitches[0].setOn(false, animated: false)
                self.actOnCalendarSwitches[1].setOn(false, animated: false)
            case 0:
                self.actOnCalendarSwitches[0].setOn(true, animated: false)
                self.actOnCalendarSwitches[1].setOn(false, animated: false)
            case 1:
                self.actOnCalendarSwitches[0].setOn(false, animated: false)
                self.actOnCalendarSwitches[1].setOn(true, animated: false)
            default:
                break
            }
            
        default:
            break
        }
    }
    
    @IBAction func searchFieldChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchStartChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchEndChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchStartSwitchChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchEndSwitchChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func syncButtonPressed(_ sender: Any) {
        let otherCalendar = 1-actOnCalendar
        if calendarMatches[otherCalendar]-eventsSyncedCount <= 0 {
            updateStatus("Sync button pressed, but nothing to do!")
        } else {
            syncCalendars(from: otherCalendar, to: actOnCalendar)
        }
        updateEventDates()
    }
    
    func syncCalendars(from fromCalendar: Int, to toCalendar: Int) {
        if eventDates[fromCalendar].count == 0 {
            updateStatus("Something went wrong...no dates to sync.")
        } else {
            for i in 0..<eventDates[fromCalendar].count {
                if !eventsSynced[fromCalendar][i] { // then still need to sync
                    // Note:  toggleEventOnCalendar will act on "actOnCalendar" setting
                    updateStatus("Syncing event for date \(eventDates[fromCalendar][i].asDateString())")
                    toggleEventOnCalendar(eventDates[fromCalendar][i])
                }
            }
        }
    }
    
    @objc func showStatusHistory(tapGestureRecognizer: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showStatusHistorySegue",sender: self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
            
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
      // move the root view up by the distance of keyboard height
      self.view.frame.origin.y = 0 - keyboardSize.height
    }

    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
      self.view.frame.origin.y = 0
    }
    
    /* UTILITY FUNCTIONS */
    
    func updateStatus(_ statusText:String) {
        print(statusText)
        statusLabel.text = dateToStringHHMMSS(Date()) + " " + statusText
        statusHistory = statusHistory + "\n" + dateToStringHHMMSS(Date()) + " " + statusText
    }
    
    func updateLog(_ statusText:String) {
        print(statusText)
        // statusLabel.text = dateToStringHHMMSS(Date()) + " " + statusText
        // statusHistory = statusHistory + "\n" + dateToStringHHMMSS(Date()) + " " + statusText
    }
    
    func stringHHMMToDate(_ time:String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: time)!
    }
    
    func dateToStringHHMMSS(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
