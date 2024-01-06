//
//  CalendarView.swift
//  kCalendarCopy
//
//  Handles displaying calendar, scrolling calendar, and handling touches
//
//  Created by Ken Polleck on 11/6/22.
//

import UIKit
// import EventKitUI
import EventKit
import FSCalendar

extension MainViewController:  FSCalendarDelegate, FSCalendarDelegateAppearance {
    
    func setupCalendarView() {
        calendarArea.addSubview(calendarView)
        calendarView.frame = calendarArea.frame
        calendarView.appearance.titleDefaultColor = UIColor.blue //UIColor.label
        
        calendarView.calendarHeaderView.isHidden = false
        calendarView.calendarHeaderView.backgroundColor = UIColor.systemTeal
        // calendarView.headerHeight = 60.0
        
        calendarView.appearance.todayColor = nil // don't highlight today differently
        // calendarView.appearance.selectionColor = nil // don't highlight selection differently
        calendarView.appearance.selectionColor = UIColor.lightGray
        calendarView.appearance.titleFont = .boldSystemFont(ofSize: 16)
        
        calendarView.appearance.titleTodayColor = nil
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        displayedMonth = calendar.currentPage
        let month = Calendar.current.component(.month, from: displayedMonth)
        monthName = DateFormatter().monthSymbols[month - 1].capitalized
        
        updateStatus("Now displaying \(monthName)")
        updateMainView()
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
    
    /*
     // Changes the CORNER radius of each date
     func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderRadiusFor date: Date) -> CGFloat {
     if date.hasSameDate(Date()) {
     return 1.0
     }
     return 0.6
     }
     */
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderSelectionColorFor date: Date) -> UIColor? {
        return UIColor.blue
    }
    
    /* Not used; change today's date to red
     func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
     if date.hasSameDate(Date()) {
     return UIColor.red
     }
     return nil
     }
     */
    
    /* Can be used to display dots under a calendar date
     func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at monthPosition: FSCalendarMonthPosition) {
     
     let dateFormatter3 = DateFormatter()
     dateFormatter3.dateFormat = "yyyy-MM-dd"
     let dateString = dateFormatter3.string(from: date)
     
     //display events as dots
     cell.eventIndicator.isHidden = false
     cell.eventIndicator.color = UIColor(red: 0.99, green: 0.40, blue: 0.29, alpha: 1.00)
     
     // print(dateString)
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
        formatter.dateFormat = "yyyy-MM-dd"
        updateLog("Selected \(formatter.string(from: date))")

        if actOnCalendar != -1 && mode == .toggle {
            toggleEventOnCalendar(date)
            updateMainView()
        } else {
            performSegue(withIdentifier: "clickedOnDate",sender: self)
        }
        
        calendarView.deselect(date) // so that selected date does not remain selected and cause confusion
    }
    
    func toggleEventOnCalendar(_ date: Date) {
        let newEvent = EKEvent(eventStore: calendarManager.eventStore)
        if actOnCalendar == -1 {
            updateLog("No calendar set to udpate.  Should never get here.")
            return
        }
        newEvent.calendar = calendarArray[actOnCalendar]
        // act on calendar
        newEvent.title = searchField.text
        newEvent.startDate = startPicker.date
        newEvent.endDate = endPicker.date
        
        newEvent.startDate = Date(date: date, time: startPicker.date)
        newEvent.endDate = Date(date: date, time: endPicker.date)
        
        updateStatus("TOGGLING \(String(describing: newEvent.title!)) from \(String(describing: newEvent.startDate!)) to \(String(describing: newEvent.endDate!)) on Calendar \(actOnCalendar)")
        
        calendarManager.toggleEvent(event: newEvent, completion: { (result) in
            switch result {
            case .success:
                break
                // print("Success.")
                // print("Toggled " + newEvent.title + " on " + newEvent.calendar.title)
            case .failure(let error):
                print("Failure trying to toggle event on calendar.")
                print(error)
            }
        })
    }
}
