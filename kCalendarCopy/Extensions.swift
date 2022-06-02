//
//  Extensions.swift
//  kCalendarCopy
//
//  Created by Ken Polleck on 5/14/22.
//

import UIKit

extension Date {
    init(_ dateString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        let date = dateStringFormatter.date(from: dateString)!
        self.init(timeInterval:0, since:date)
    }
    
    init (time timeString:String) {
       let dateStringFormatter = DateFormatter()
       dateStringFormatter.dateFormat = "HH:mm"
       dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
       let date = dateStringFormatter.date(from: timeString)!
       self.init(timeInterval:0, since:date)
   }
    
    init (date:Date, time:Date) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateStringFormatter.string(from: date)
        
        let timeStringFormatter = DateFormatter()
        timeStringFormatter.dateFormat = "HH:mm"
        let timeString = timeStringFormatter.string(from: time)
        
        let dateAndTimeStringFormatter = DateFormatter()
        dateAndTimeStringFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date = dateAndTimeStringFormatter.date(from: dateString + " " + timeString)!
        self.init(timeInterval:0, since:date)
    }
    
    func stripTime() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let date = Calendar.current.date(from: components)
        return date!
    }
        
    func stripDate() -> Date {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        print(components)
        let date = Calendar.current.date(from: components)
        return date!
    }
    
    func hasSameTime(_ date : Date) -> Bool {
        let components1 = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        let components2 = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let diff = Calendar.current.dateComponents([.hour, .minute, .second], from: components1, to: components2)
        
        if (diff.hour == 0 && diff.minute == 0 && diff.second == 0) {
            return true
        } else {
            return false
        }
    }
    
    func hasSameDate(_ date : Date) -> Bool {
        let components1 = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let components2 = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let diff = Calendar.current.dateComponents([.year, .month, .day], from: components1, to: components2)
        
        if (diff.year == 0 && diff.month == 0 && diff.day == 0) {
            return true
        } else {
            return false
        }
    }
    
    func formatDate(_ format : String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        // Don't know if next line is needed or what it does
        // dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        return dateFormatter.string(from: self)
    }
}

extension UIColor {
    func blend(_ color1: UIColor) -> UIColor {
        let alphaAdjust = 0.3
        let c1 = color1.rgbaTuple()
        let c2 = self.rgbaTuple()

        let c1r = CGFloat(c1.r)
        let c1g = CGFloat(c1.g)
        let c1b = CGFloat(c1.b)

        let c2r = CGFloat(c2.r)
        let c2g = CGFloat(c2.g)
        let c2b = CGFloat(c2.b)

        let r = c1r * alphaAdjust + c2r * alphaAdjust
        let g = c1g * alphaAdjust + c2g * alphaAdjust
        let b = c1b * alphaAdjust + c2b * alphaAdjust

        return UIColor.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
    
    func blendAlpha(coverColor: UIColor) -> UIColor {
        let c1 = coverColor.rgbaTuple()
        let c2 = self.rgbaTuple()

        let c1r = CGFloat(c1.r)
        let c1g = CGFloat(c1.g)
        let c1b = CGFloat(c1.b)

        let c2r = CGFloat(c2.r)
        let c2g = CGFloat(c2.g)
        let c2b = CGFloat(c2.b)

        let r = c1r * c1.a + c2r  * (1 - c1.a)
        let g = c1g * c1.a + c2g  * (1 - c1.a)
        let b = c1b * c1.a + c2b  * (1 - c1.a)

        return UIColor.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
    
    func rgbaTuple() -> (r: CGFloat, g: CGFloat, b: CGFloat,a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        r = r * 255
        g = g * 255
        b = b * 255

        return ((r),(g),(b),a)
    }
}
