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

class MainViewController: UIViewController, FSCalendarDelegate, FSCalendarDelegateAppearance, EKCalendarChooserDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    enum CalendarTouchMode { case select, toggle}

    let defaults = UserDefaults.standard
    
    let calendarManager = EventsCalendarManager()
    var selectedCalendar : EKCalendar?
    var calendarArray = [EKCalendar?]()
    var calendarList: [String] = ["Choose Calendar 1", "Choose Calendar 2"]
    var calendarColor: [UIColor] = [.gray, .gray]
    var calendarValid: [Bool] = [false, false]
    
    var eventDates: [[Date]] = [[Date("2022-05-01")],[Date("2022-05-01")]]
    var possibleEvents = [EKEvent]()
    var matchingEvents = [EKEvent]()
    
    var matchEventStart = "8:00"
    var matchEventEnd = "20:00"
    
    var selectedCalendarRow = 0
    var calendarTouchMode : CalendarTouchMode = .select
    var selectedDate = Date()
    
    var calendarView = FSCalendar()
    @IBOutlet weak var calendarArea: UIView!
    @IBOutlet weak var calendarTableView: UITableView!
    
    @IBOutlet weak var modeLabel: UILabel!
    
    @IBOutlet weak var matchEventTitle: UITextField!
    @IBOutlet weak var matchEventStartPicker: UIDatePicker!
    @IBOutlet weak var matchEventEndPicker: UIDatePicker!
    @IBOutlet weak var matchEventTitleSwitch: UISwitch!
    @IBOutlet weak var matchEventStartSwitch: UISwitch!
    @IBOutlet weak var matchEventEndSwitch: UISwitch!
    @IBOutlet weak var matchEventTitleExactSwitch: UISwitch!
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.calendarTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        // Delegate to change calendar colors
        calendarView.delegate = self
        
        // Text Field Delegates (to dismiss the keyboare after enter)
        matchEventTitle.delegate = self
        
        // Delegate to create and process clicks on the calendarTableView
        calendarTableView.delegate = self
        calendarTableView.dataSource = self
        
        // Calendar Mode
        calendarTouchMode = .select
        modeLabel.text = "In Select Mode"
        modeLabel.backgroundColor = UIColor.systemBlue
        modeLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(modeLabelTouched(tapGestureRecognizer:)))
        modeLabel.addGestureRecognizer(tapGesture)

        matchEventTitle.text = ""
        // matchEventStart.text = "12:00"
        // matchEventEnd.text = "12:00"
        
        matchEventStartPicker.contentHorizontalAlignment = .left
        matchEventEndPicker.contentHorizontalAlignment = .left
        matchEventTitleSwitch.setOn(true, animated: false)
        matchEventTitleExactSwitch.setOn(true, animated: false)
        matchEventStartSwitch.setOn(true, animated: false)
        matchEventEndSwitch.setOn(true, animated: false)
        
        setupCalendarView()
        
        // default defaults
        calendarArray.append(calendarManager.eventStore.defaultCalendarForNewEvents)
        calendarArray.append(calendarManager.eventStore.defaultCalendarForNewEvents)
        calendarList = ["Choose Calendar 1", "Choose Calendar 2"]
        calendarColor = [.gray, .gray]
        calendarValid = [false, false]
        
        // Set selected calendars from defaults
        let calendarIDArray = defaults.object(forKey:"calendarIDArray") as? [String] ?? [String]()
        
        // print("Loading defaults")
        
        if calendarIDArray.count > 0 && calendarIDArray[0] != "" {
            calendarArray[0] = calendarManager.eventStore.calendar(withIdentifier: calendarIDArray[0])
            calendarList[0] = calendarArray[0]!.title
            calendarColor[0] = UIColor(cgColor: calendarArray[0]!.cgColor)
            calendarValid[0] = true
        }
        if calendarIDArray.count > 1 && calendarIDArray[1] != "" {
            calendarArray[1] = calendarManager.eventStore.calendar(withIdentifier: calendarIDArray[1])
            calendarList[1] = calendarArray[1]!.title
            calendarColor[1] = UIColor(cgColor: calendarArray[1]!.cgColor)
            calendarValid[1] = true
        }
        // calendarTableView.reloadData()
        
        matchEventStartPicker.date = Date(time: matchEventStart)
        matchEventEndPicker.date = Date(time: matchEventEnd)
        matchEventStartPicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        matchEventEndPicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
     
        // call the 'keyboardWillShow' function when the view controller receive the notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
          
        // call the 'keyboardWillHide' function when the view controlelr receive notification that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func setupCalendarView() {
        calendarArea.addSubview(calendarView)
        calendarView.frame = calendarArea.frame
        calendarView.appearance.titleDefaultColor = UIColor.label
        
        calendarView.calendarHeaderView.isHidden = false
        calendarView.calendarHeaderView.backgroundColor = UIColor.systemTeal
        // calendarView.headerHeight = 60.0
        
        calendarView.appearance.todayColor = nil // don't highlight today differently
        // calendarView.appearance.selectionColor = nil // don't highlight selection differently
        calendarView.appearance.selectionColor = UIColor.lightGray
        calendarView.appearance.titleFont = .boldSystemFont(ofSize: 16)
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        return colorDate(date)
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
        return colorDate(date)
    }
    
    func colorDate (_ date: Date) -> UIColor? {
        
        let onCal0 = eventDates[0].contains(date) && calendarValid[0]
        let onCal1 = eventDates[1].contains(date) && calendarValid[1]
    
        switch (onCal0,onCal1) {
        case (true,true):
            return calendarColor[0].blend(calendarColor[1])
        case (true,false):
            return calendarColor[0]
        case (false,true):
            return calendarColor[1]
        case (false,false):
            return nil
        }
    }
    
    // Put a circular red border around today's date
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderDefaultColorFor date: Date) -> UIColor? {
        if date.hasSameDate(Date()) {
            return UIColor.red
        }
        return nil
    }
    
    /* Not used; change today's date to red
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if date.hasSameDate(Date()) {
            return UIColor.red
        }
        return nil
    }
    */
    
    /*
    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        let dateFormatter3 = DateFormatter()
        dateFormatter3.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter3.string(from: date)
        
        //display events as dots
        cell.eventIndicator.isHidden = false
        cell.eventIndicator.color = UIColor(red: 0.99, green: 0.40, blue: 0.29, alpha: 1.00)
        
        print(dateString)
        cell.eventIndicator.numberOfEvents = 3
    }
    */
    
    // Next doesn't seem to be doing anything
    func calendar(calendar: FSCalendar, numberOfEventsForDate date: NSDate) -> Int {
        return 2
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        // print("Date selected \(formatter.string(from: date))")
        
        if calendarTouchMode == .select {
            performSegue(withIdentifier: "selectedDate",sender: self)
        } else if calendarTouchMode == .toggle {
            copyEvent()
            updateEventDates()
        }
    }
    
    func copyEvent() {
        let newEvent = EKEvent(eventStore: calendarManager.eventStore)
        newEvent.calendar = calendarArray[1] // Second calendar
        newEvent.title = matchEventTitle.text
        newEvent.startDate = matchEventStartPicker.date
        newEvent.endDate = matchEventEndPicker.date
        
        newEvent.startDate = Date(date: selectedDate, time: matchEventStartPicker.date)
        newEvent.endDate = Date(date:selectedDate, time: matchEventEndPicker.date)

        print(newEvent.startDate)
        
        calendarManager.toggleEvent(event: newEvent, completion: { (result) in
            switch result {
            case .success:
              print("Success.")
 //               print("Toggled " + newEvent.title + " on " + newEvent.calendar.title)
            case .failure(let error):
 //             print("Failure")
                print(error)
            }
        })
    }
    
    @objc func modeLabelTouched(tapGestureRecognizer: UITapGestureRecognizer) {
        if calendarTouchMode == .select {
            calendarTouchMode = .toggle
            modeLabel.text = "In Event Add/Remove Mode"
            modeLabel.backgroundColor = UIColor.red
        } else {
            calendarTouchMode = .select
            modeLabel.text = "In Select Mode"
            modeLabel.backgroundColor = UIColor.systemBlue
        }
    }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        
        // Create date formatter
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let selectedDate: String = dateFormatter.string(from: sender.date)
        
        // print("Selected value \(selectedDate)")
        if sender == matchEventStartPicker {
            matchEventStart = selectedDate
        }
        
        if sender == matchEventEndPicker {
            matchEventEnd = selectedDate
        }
        
        self.view.endEditing(true)
        
        updateEventDates()
    }
    
    @objc func cancelDatePicker() {
        self.view.endEditing(true)
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return self.calendarList.count }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = (self.calendarTableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell?)!
        
        // set the content from the data model
        cell.textLabel?.text = self.calendarList[indexPath.row]
        cell.backgroundColor = self.calendarColor[indexPath.row]
        
        // set up long press gesture recognizer
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.tableViewCellLongPressed))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        cell.addGestureRecognizer(longPressGestureRecognizer)
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // print("You tapped cell number \(indexPath.row).")
        selectedCalendarRow = indexPath.row
        showCalendarChooser()
    }
    
    @objc func tableViewCellLongPressed() {
        print("Long Press")
    }
    
    // *** SEGUE PROCESSING ***

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        // print (segue.identifier)

        if (segue.identifier == "selectedDate") {
            if let destinationVC = segue.destination as? EventViewController {
                destinationVC.mainVC = self
                // destinationVC.calendarArray = self.calendarArray
            }
        }
    }
    
    func showCalendarChooser() {
        let vc = EKCalendarChooser(selectionStyle: .single, displayStyle: .allCalendars, entityType: .event, eventStore: calendarManager.eventStore)
        vc.showsDoneButton = false
        vc.showsCancelButton = true
        vc.delegate = self
        
        // let afterPresent = { print("presented")} // One way to write code to be shown as a completion hanlder
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        // Note:  Code continues while vc is being presented
    }
    
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        // print("Dismissing calendarChooser")
        // print(calendarChooser.selectedCalendars)
        calendarChooser.dismiss(animated: true, completion: nil)
    }
    
    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        selectedCalendar = calendarChooser.selectedCalendars.first!
        // print(calendarChooser.selectedCalendars)
        // print("Changed calendarChooser selection to " + selectedCalendar!.title)
        calendarChooser.dismiss(animated: true, completion: nil)
        
        calendarArray[selectedCalendarRow] = selectedCalendar
        calendarList[selectedCalendarRow] = selectedCalendar!.title
        calendarColor[selectedCalendarRow] = UIColor(cgColor: selectedCalendar!.cgColor)
        calendarValid[selectedCalendarRow] = true
        
        defaults.set([calendarArray[0]?.calendarIdentifier,calendarArray[1]?.calendarIdentifier], forKey: "calendarIDArray")

        calendarTableView.reloadData()
        
        updateEventDates()
    }
    
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        // print("Cancelling calendarChooser")
        calendarChooser.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func updateEventDates() { // get dates from both calendars
        updateEventDates(0)
        updateEventDates(1)
        
        calendarView.reloadData()
    }
    
    func updateEventDates(_ calendarIndex: Int) {
        if !calendarValid[calendarIndex] { return }
            
        guard let oneCalendar = calendarArray[calendarIndex] else {
            return
        }
        
        let calendarsToSearch : [EKCalendar] = [oneCalendar]
        
        let predicate = calendarManager.eventStore.predicateForEvents(withStart: Date("2022-01-01"), end: Date("2022-12-31"), calendars: calendarsToSearch)
        let possibleEvents = calendarManager.eventStore.events(matching: predicate)
        // print("\(possibleEvents.count) possible events found.")
        
        matchingEvents.removeAll()
        for e in possibleEvents {
            let eventTitle = e.title.replacingOccurrences(of: "\\", with: "")
            // *TODO* Above is probably not the best way to deal with escape character from calendar entry
            // print("Comparing calendar event '\(eventTitle)' with '\(String(describing: matchEventTitle.text!))'")
            if (matchEventTitleSwitch.isOn && matchEventTitleExactSwitch.isOn && eventTitle != matchEventTitle.text) { continue }
            if (matchEventTitleSwitch.isOn && !(eventTitle.lowercased().contains(matchEventTitle.text!.lowercased()))) { continue }
            // print("Comparing calendar time \(String(describing: e.startDate!)) with \(String(describing: matchEventStart))")
            if (matchEventStartSwitch.isOn && !e.startDate.hasSameTime(timeFromString(matchEventStart))) { continue }
            // print("Comparing calendar time \(String(describing: e.endDate!)) with \(String(describing: matchEventEnd))")
            if (matchEventEndSwitch.isOn && !e.endDate.hasSameTime(timeFromString(matchEventEnd))) { continue }
            // print("Matches!!!")
            matchingEvents.append(e)
        }
        
        eventDates[calendarIndex].removeAll()
        for event in matchingEvents {
            eventDates[calendarIndex].append(event.startDate.stripTime())
        }
        // print("\(matchingEvents.count) matching events found.")
        // print(eventDates)
    }
    
    @IBAction func matchEventTitleChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchEventStartChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchEventEndChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchEventTitleSwitchChange(_ sender: Any) {
        if !matchEventTitleSwitch.isOn {
            matchEventTitleExactSwitch.setOn(false, animated: true)
            matchEventStartSwitch.setOn(false, animated: true)
            matchEventEndSwitch.setOn(false, animated: true)
        }
        updateEventDates()
    }
    @IBAction func matchEventStartSwitchChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchEventEndSwitchChange(_ sender: Any) {
        updateEventDates()
    }
    @IBAction func matchEventTitleExactSwitchChange(_ sender: Any) {
        if matchEventTitleExactSwitch.isOn {
            matchEventTitleSwitch.setOn(true, animated: true)
        }
        updateEventDates()
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
    
    func timeFromString(_ stringTime:String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: stringTime)!
    }
}
