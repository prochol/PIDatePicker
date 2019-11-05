//
//  PIDatePicker.swift
//  Pods
//
//  Created by Christopher Jones on 3/30/15.
//
//

import UIKit
import Foundation

public class PIDatePicker: UIControl, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: -
    // MARK: Public Properties
    public var delegate: PIDatePickerDelegate?
    
    /// The font for the date picker.
    public var font = UIFont.systemFont(ofSize: 15.0)
    
    /// The text color for the date picker components.
    public var textColor = UIColor.black
    
    /// The minimum date to show for the date picker. Set to NSDate.distantPast() by default
    public var minimumDate = NSDate.distantPast {
        didSet {
            self.validateMinimumAndMaximumDate()
        }
    }
    
    /// The maximum date to show for the date picker. Set to NSDate.distantFuture() by default
    public var maximumDate = NSDate.distantFuture {
        didSet {
            self.validateMinimumAndMaximumDate()
        }
    }
    
    /// The current locale to use for formatting the date picker. By default, set to the device's current locale
    public var locale : Locale = Locale.current {
        didSet {
            self.calendar.locale = self.locale
        }
    }
    
    /// Time zone.
    public var timezone : TimeZone = TimeZone.current {
        
        didSet {
            self.calendar.timeZone = self.timezone
        }
    }
    
    /// The current date value of the date picker.
    public private(set) var date = Date()
    
    // MARK: -
    // MARK: Private Variables
    
    private let maximumNumberOfRows = Int(INT16_MAX)
    
    /// The internal picker view used for laying out the date components.
    private let pickerView = UIPickerView()
    
    /// Calculates the current calendar components for the current date.
    private var currentCalendarComponents : DateComponents {
        get {
            return self.calendar.dateComponents([.year, .month, .day], from: self.date)
        }
    }
    
    /// Gets the text color to be used for the label in a disabled state
    private var disabledTextColor : UIColor {
        get {
            var r : CGFloat = 0
            var g : CGFloat = 0
            var b : CGFloat = 0
            
            self.textColor.getRed(&r, green: &g, blue: &b, alpha: nil)
            
            return UIColor(red: r, green: g, blue: b, alpha: 0.35)
        }
    }
    
    /// The calendar used for formatting dates.
    private var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    
    /// The order in which each component should be ordered in.
    private var datePickerComponentOrdering = [PIDatePickerComponents]()
    
    // MARK: -
    // MARK: LifeCycle
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    /**
     Handles the common initialization amongst all init()
     */
    func commonInit() {
        
        self.refreshComponentOrdering()
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.pickerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        
        self.addSubview(self.pickerView)
        
        let topConstraint = NSLayoutConstraint(item: self.pickerView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.pickerView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let leftConstraint = NSLayoutConstraint(item: self.pickerView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self.pickerView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        
        self.addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        
        super.layoutSubviews()
        pickerView.layoutSubviews()
    }
    
    public override func setNeedsLayout() {
        
        super.setNeedsLayout()
        pickerView.setNeedsLayout()
    }
    
    public override func layoutIfNeeded() {
        
        super.layoutIfNeeded()
        pickerView.layoutIfNeeded()
    }
    
    // MARK: -
    // MARK: Override
    public override var intrinsicContentSize: CGSize {
        return self.pickerView.intrinsicContentSize
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        self.reloadAllComponents()
        
        self.setDate(self.date)
    }
    
    // MARK: -
    // MARK: Public
    
    /**
    Reloads all of the components in the date picker.
    */
    public func reloadAllComponents() {
        self.refreshComponentOrdering()
        self.pickerView.reloadAllComponents()
    }
    
    /**
     Sets the current date value for the date picker.
     
     :param: date     The date to set the picker to.
     :param: animated True if the date picker should changed with an animation; otherwise false,
     */
    public func setDate(_ date: Date, animated : Bool) {
        self.date = date
        self.updatePickerViewComponentValuesAnimated(animated: animated)
    }
    
    // MARK: -
    // MARK: Private
    
    /**
    Sets the current date with no animation.
    
    :param: date The date to be set.
    */
    private func setDate(_ date : Date) {
        self.setDate(date, animated: false)
    }
    
    /**
     Creates a new date formatter with the locale and calendar
     
     :returns: A new instance of NSDateFormatter
     */
    private func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = self.calendar
        dateFormatter.locale = self.locale
        
        return dateFormatter
    }
    
    /**
     Refreshes the ordering of components based on the current locale. Calling this function will not refresh the picker view.
     */
    private func refreshComponentOrdering() {
        
        self.datePickerComponentOrdering = [PIDatePickerComponents(rawValue: "M")!, PIDatePickerComponents(rawValue: "d")!, PIDatePickerComponents(rawValue: "y")!]
    }
    
    /**
     Validates that the set minimum and maximum dates are valid.
     */
    private func validateMinimumAndMaximumDate() {
        let ordering = self.minimumDate.compare(self.maximumDate)
        if ordering != .orderedAscending {
            fatalError("Cannot set a maximum date that is equal or less than the minimum date.")
        }
    }
    
    /**
     Gets the value of the current component at the specified row.
     
     :param: row            The row index whose value is required
     :param: componentIndex The component index for the row.
     
     :returns: A string containing the value of the current row at the component index.
     */
    private func titleForRow(row : Int, inComponentIndex componentIndex: Int) -> String {
        let dateComponent = self.componentAtIndex(index: componentIndex)
        
        let value = self.rawValue(forRow: row, inComponent: dateComponent)
        
        if dateComponent == PIDatePickerComponents.month {
            let dateFormatter = self.dateFormatter()
            return dateFormatter.monthSymbols[value - 1]
        } else {
            return String(value)
        }
    }
    
    /**
     Gets the value of the input component using the current date.
     
     :param: component The component whose value is needed.
     
     :returns: The value of the component.
     */
    private func valueForDateComponent(component : PIDatePickerComponents) -> Int{
        if component == .year {
            return self.currentCalendarComponents.year!
        } else if component == .day {
            return self.currentCalendarComponents.day!
        } else {
            return self.currentCalendarComponents.month!
        }
    }
    
    /**
     Gets the maximum range for the specified date picker component.
     
     :param: component The component to get the range for.
     
     :returns: The maximum date range for that component.
     */
    private func maximumRange(forComponent component: PIDatePickerComponents) -> Range<Int>? {
        var calendarComponent: Calendar.Component
        if component == .year {
            calendarComponent = .year
        } else if component == .day {
            calendarComponent = .day
        } else {
            calendarComponent = .month
        }
        
        return self.calendar.maximumRange(of: calendarComponent)
    }
    
    /**
     Calculates the raw value of the row at the current index.
     
     :param: row       The row to get.
     :param: component The component which the row belongs to.
     
     :returns: The raw value of the row, in integer. Use NSDateComponents to convert to a usable date object.
     */
    private func rawValue(forRow row: Int, inComponent component: PIDatePickerComponents) -> Int {
        let calendarUnitRange = self.maximumRange(forComponent: component)
        return calendarUnitRange!.startIndex + (row % calendarUnitRange!.count)
    }
    
    /**
     Checks if the specified row should be enabled or not.
     
     :param: row       The row to check.
     :param: component The component to check the row in.
     
     :returns: YES if the row should be enabled; otherwise NO.
     */
    private func isRowEnabled(row: Int, forComponent component : PIDatePickerComponents) -> Bool {
        
        let rawValue = self.rawValue(forRow: row, inComponent: component)
        
        var components = DateComponents()
        components.year = self.currentCalendarComponents.year
        components.month = self.currentCalendarComponents.month
        components.day = self.currentCalendarComponents.day
        
        if component == .year {
            components.year = rawValue
        } else if component == .day {
            components.day = rawValue
        } else if component == .month {
            components.month = rawValue
        }
        
        let dateForRow = self.calendar.date(from: components)!
        
        return self.dateIsInRange(date: dateForRow)
    }
    
    /**
     Checks if the input date falls within the date picker's minimum and maximum date ranges.
     
     :param: date The date to be checked.
     
     :returns: True if the input date is within range of the minimum and maximum; otherwise false.
     */
    private func dateIsInRange(date: Date) -> Bool {
        return self.minimumDate.compare(date) != ComparisonResult.orderedDescending &&
            self.maximumDate.compare(date) != ComparisonResult.orderedAscending
    }
    
    /**
     Updates all of the date picker components to the value of the current date.
     
     :param: animated True if the update should be animated; otherwise false.
     */
    private func updatePickerViewComponentValuesAnimated(animated : Bool) {
        for dateComponent in self.datePickerComponentOrdering {
            self.setIndexOfComponent(component: dateComponent, animated: animated)
        }
    }
    
    /**
     Updates the index of the specified component to its relevant value in the current date.
     
     :param: component The component to be updated.
     :param: animated  True if the update should be animated; otherwise false.
     */
    private func setIndexOfComponent(component: PIDatePickerComponents, animated: Bool) {
        self.setIndexOfComponent(component: component, toValue: self.valueForDateComponent(component: component), animated: animated)
    }
    
    /**
     Updates the index of the specified component to the input value.
     
     :param: component The component to be updated.
     :param: value     The value the component should be updated ot.
     :param: animated  True if the update should be animated; otherwise false.
     */
    private func setIndexOfComponent(component: PIDatePickerComponents, toValue value: Int, animated: Bool) {
        let componentRange = self.maximumRange(forComponent: component)
        
        let idx = value - componentRange!.startIndex
        let middleIndex = (self.maximumNumberOfRows / 2) - (maximumNumberOfRows / 2) % componentRange!.count + idx
        
        var componentIndex = 0
        
        for (index, dateComponent) in self.datePickerComponentOrdering.enumerated() {
            if (dateComponent == component) {
                componentIndex = index
            }
        }
        
        self.pickerView.selectRow(middleIndex, inComponent: componentIndex, animated: animated)
    }
    
    /**
     Gets the component type at the current component index.
     
     :param: index The component index
     
     :returns: The date picker component type at the index.
     */
    private func componentAtIndex(index: Int) -> PIDatePickerComponents {
        return self.datePickerComponentOrdering[index]
    }
    
    /**
     Gets the number of days of the specified month in the specified year.
     
     :param: month The month whose maximum date value is requested.
     :param: year  The year for which the maximum date value is required.
     
     :returns: The number of days in the month.
     */
    private func numberOfDays(forMonth month : Int, inYear year : Int) -> Int {
        var components = DateComponents()
        components.month = month
        components.day = 1
        components.year = year
        
        let calendarRange = self.calendar.range(of: .day, in: .month, for: self.calendar.date(from: components)!)
        let numberOfDaysInMonth = calendarRange!.count
        
        return numberOfDaysInMonth
    }
    
    /**
     Determines if updating the specified component to the input value would evaluate to a valid date using the current date values.
     
     :param: value     The value to be updated to.
     :param: component The component whose value should be updated.
     
     :returns: True if updating the component to the specified value would result in a valid date; otherwise false.
     */
    private func isValidValue(value : Int, forComponent component: PIDatePickerComponents) -> Bool {
        if (component == .year) {
            let numberOfDaysInMonth = self.numberOfDays(forMonth: self.currentCalendarComponents.month!, inYear: value)
            return self.currentCalendarComponents.day! <= numberOfDaysInMonth
        } else if (component == .day) {
            let numberOfDaysInMonth = self.numberOfDays(forMonth: self.currentCalendarComponents.month!, inYear: self.currentCalendarComponents.year!)
            return value <= numberOfDaysInMonth
        } else if (component == .month) {
            let numberOfDaysInMonth = self.numberOfDays(forMonth: value, inYear: self.currentCalendarComponents.year!)
            return self.currentCalendarComponents.day! <= numberOfDaysInMonth
        }
        
        return true
    }
    
    /**
     Creates date components by updating the specified component to the input value. This does not do any date validation.
     
     :param: component The component to be updated.
     :param: value     The value the component should be updated to.
     
     :returns: The components by updating the current date's components to the specified value.
     */
    private func currentCalendarComponentsByUpdatingComponent(component : PIDatePickerComponents, toValue value : Int) -> DateComponents {
        var components = self.currentCalendarComponents
        
        if (component == .month) {
            components.month = value
        } else if (component == .day) {
            components.day = value
        } else {
            components.year = value
        }
        
        return components
    }
    
    /**
     Creates date components by updating the specified component to the input value. If the resulting value is not a valid date object, the components will be updated to the closest best value.
     
     :param: component The component to be updated.
     :param: value     The value the component should be updated to.
     
     :returns: The components by updating the specified value; the components will be a valid date object.
     */
    private func validDateValueByUpdatingComponent(component : PIDatePickerComponents, toValue value : Int) -> DateComponents {
        var components = self.currentCalendarComponentsByUpdatingComponent(component: component, toValue: value)
        
        if (!self.isValidValue(value: value, forComponent: component)) {
            if (component == .month) {
                components.day = self.numberOfDays(forMonth: value, inYear: components.year!)
            } else if (component == .day) {
                components.day = self.numberOfDays(forMonth: components.month!, inYear:components.year!)
            } else {
                components.day = self.numberOfDays(forMonth: components.month!, inYear: value)
            }
        }
        
        return components
    }
    
    // MARK: -
    // MARK: Protocols
    // MARK: UIPickerViewDelegate
    
    public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let datePickerComponent = self.componentAtIndex(index: component)
        let value = self.rawValue(forRow: row, inComponent: datePickerComponent)
        
        // Create the newest valid date components.
        let components = self.validDateValueByUpdatingComponent(component: datePickerComponent, toValue: value)
        
        // If the resulting components are not in the date range ...
        if (!self.dateIsInRange(date: self.calendar.date(from: components as DateComponents)!)) {
            // ... go back to original date
            self.setDate(self.date, animated: true)
        } else {
            // Get the components that would result by just force-updating the current components.
            let rawComponents = self.currentCalendarComponentsByUpdatingComponent(component: datePickerComponent, toValue: value)
            
            if (rawComponents.day != components.day) {
                // Only animate the change if the day value is not a valid date.
                self.setIndexOfComponent(component: .day, toValue: components.day!, animated: self.isValidValue(value: components.day!, forComponent: .day))
            }
            
            if (rawComponents.month != components.month) {
                self.setIndexOfComponent(component: .month, toValue: components.day!, animated: datePickerComponent != .month)
            }
            
            if (rawComponents.year != components.year) {
                self.setIndexOfComponent(component: .year, toValue: components.day!, animated: datePickerComponent != .year)
            }
            
            self.date = self.calendar.date(from: components as DateComponents)!
            self.sendActions(for: .valueChanged)
        }
        
        self.delegate?.pickerView(pickerView: self, didSelectRow: row, inComponent: component)
    }
    
    public func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel == nil ? UILabel() : view as! UILabel
        
        let pickerComponent = self.componentAtIndex(index: component)
        
        label.font = self.font
        label.textColor = self.textColor
        label.text = self.titleForRow(row: row, inComponentIndex: component)
        label.textAlignment = pickerComponent == .month ? NSTextAlignment.left : pickerComponent == .day ? NSTextAlignment.center : NSTextAlignment.right
        label.textColor = self.isRowEnabled(row: row, forComponent: pickerComponent) ? self.textColor : self.disabledTextColor
        
        return label
    }
    
    public func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let widthBuffer = 25.0
        
        let calendarComponent = self.componentAtIndex(index: component)
        let stringSizingAttributes = [NSAttributedString.Key.font : self.font]
        var size = 0.01
        
        if calendarComponent == .month {
            let dateFormatter = self.dateFormatter()
            
            // Get the length of the longest month string and set the size to it.
            for symbol in dateFormatter.monthSymbols as [String] {
                let monthSize = NSString(string: symbol).size(withAttributes: stringSizingAttributes)
                size = max(size, Double(monthSize.width))
            }
        } else if calendarComponent == .day{
            // Pad the day string to two digits
            let dayComponentSizingString = NSString(string: "00")
            size = Double(dayComponentSizingString.size(withAttributes: stringSizingAttributes).width)
        } else if calendarComponent == .year  {
            // Pad the year string to four digits.
            let yearComponentSizingString = NSString(string: "0000")
            size = Double(yearComponentSizingString.size(withAttributes: stringSizingAttributes).width)
        }
        
        // Add the width buffer in order to allow the picker components not to run up against the edges
        return CGFloat(ceil(size) + widthBuffer)
    }
    
    
    // MARK: UIPickerViewDataSource
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.maximumNumberOfRows
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
}
