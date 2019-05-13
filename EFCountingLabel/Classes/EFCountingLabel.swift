//
//  EFCountingLabel.swift
//  EFCountingLabel
//
//  Created by EyreFree on 2016/12/11.
//
//  Copyright (c) 2017 EyreFree <eyrefree@eyrefree.org>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

// MARK:- EFTransition
public protocol EFLabelCounter {

    func update(_ t: CGFloat, easingRate: CGFloat) -> CGFloat
}

// MARK:- EFLabelCountingMethod
public enum EFLabelCountingMethod: Int, EFLabelCounter {

    case linear = 0
    case easeIn = 1
    case easeOut = 2
    case easeInOut = 3
    case easeInBounce = 4
    case easeOutBounce = 5

    public func update(_ t: CGFloat, easingRate: CGFloat) -> CGFloat {
        let percent: CGFloat = t
        switch self {
        case .linear:
            return percent
        case .easeIn:
            return pow(t, easingRate)
        case .easeOut:
            return 1.0 - pow(1.0 - t, easingRate)
        case .easeInOut:
            let newt: CGFloat = 2 * t
            if newt < 1 {
                return 0.5 * pow(newt, easingRate)
            } else {
                return 0.5 * (2.0 - pow(2.0 - newt, easingRate))
            }
        case .easeInBounce:
            if t < 4.0 / 11.0 {
                return 1.0 - (pow(11.0 / 4.0, 2) * pow(t, 2)) - t
            } else if t < 8.0 / 11.0 {
                return 1.0 - (3.0 / 4.0 + pow(11.0 / 4.0, 2) * pow(t - 6.0 / 11.0, 2)) - t
            } else if t < 10.0 / 11.0 {
                return 1.0 - (15.0 / 16.0 + pow(11.0 / 4.0, 2) * pow(t - 9.0 / 11.0, 2)) - t
            }
            return 1.0 - (63.0 / 64.0 + pow(11.0 / 4.0, 2) * pow(t - 21.0 / 22.0, 2)) - t
        case .easeOutBounce:
            if t < 4.0 / 11.0 {
                return pow(11.0 / 4.0, 2) * pow(t, 2)
            } else if t < 8.0 / 11.0 {
                return 3.0 / 4.0 + pow(11.0 / 4.0, 2) * pow(t - 6.0 / 11.0, 2)
            } else if t < 10.0 / 11.0 {
                return 15.0 / 16.0 + pow(11.0 / 4.0, 2) * pow(t - 9.0 / 11.0, 2)
            }
            return 63.0 / 64.0 + pow(11.0 / 4.0, 2) * pow(t - 21.0 / 22.0, 2)
        }
    }
}

//MARK: - EFCountingLabel
open class EFCountingLabel: UILabel {

    public var format: String = "%f"
    public var method: EFLabelCounter = EFLabelCountingMethod.linear
    public var animationDuration: TimeInterval = 2
    public var formatBlock: ((CGFloat) -> String)?
    public var attributedFormatBlock: ((CGFloat) -> NSAttributedString)?
    public var completionBlock: (() -> Void)?
    public var easingRate: CGFloat = 3

    private var startingValue: CGFloat = 0
    private var destinationValue: CGFloat = 1
    private var progress: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var totalTime: TimeInterval = 1
    private var easingRateInner: CGFloat = 3

    private var timer: CADisplayLink?
    private var counter: EFLabelCounter = EFLabelCountingMethod.linear

    public var isCounting: Bool {
        return timer != nil
    }

    public var currentValue: CGFloat {
        if progress == 0 {
            return 0
        } else if progress >= totalTime {
            return destinationValue
        }

        let percent = progress / totalTime
        let updateVal = counter.update(CGFloat(percent), easingRate: easingRateInner)

        return startingValue + updateVal * (destinationValue - startingValue)
    }

    public func countFrom(_ startValue: CGFloat, to endValue: CGFloat) {
        countFrom(startValue, to: endValue, withDuration: animationDuration)
    }

    public func countFrom(_ startValue: CGFloat, to endValue: CGFloat, withDuration duration: TimeInterval) {
        startingValue = startValue
        destinationValue = endValue

        // remove any (possible) old timers
        self.timer?.invalidate()
        self.timer = nil

        if duration == 0.0 {
            // No animation
            setTextValue(endValue)
            runCompletionBlock()
            return
        }

        progress = 0
        totalTime = duration
        lastUpdate = CACurrentMediaTime()

        counter = method
        easingRateInner = easingRate

        let timer = CADisplayLink(target: self, selector: #selector(updateValue(_:)))
        if #available(iOS 10.0, *) {
            timer.preferredFramesPerSecond = 30
        } else {
            timer.frameInterval = 2
        }
        timer.add(to: .main, forMode: .default)
        timer.add(to: .main, forMode: .tracking)
        self.timer = timer
    }

    public func countFromCurrentValueTo(_ endValue: CGFloat) {
        countFrom(currentValue, to: endValue)
    }

    public func countFromCurrentValueTo(_ endValue: CGFloat, withDuration duration: TimeInterval) {
        countFrom(currentValue, to: endValue, withDuration: duration)
    }

    public func countFromZeroTo(_ endValue: CGFloat) {
        countFrom(0, to: endValue)
    }

    public func countFromZeroTo(_ endValue: CGFloat, withDuration duration: TimeInterval) {
        countFrom(0, to: endValue, withDuration: duration)
    }

    public func stopAtCurrentValue() {
        timer?.invalidate()
        timer = nil

        setTextValue(currentValue)
    }

    @objc public func updateValue(_ timer: Timer) {
        // update progress
        let now = CACurrentMediaTime()
        progress += now - lastUpdate
        lastUpdate = now

        if progress >= totalTime {
            self.timer?.invalidate()
            self.timer = nil
            progress = totalTime
        }

        setTextValue(currentValue)

        if progress == totalTime {
            runCompletionBlock()
        }
    }

    public func setTextValue(_ value: CGFloat) {
        if let tryAttributedFormatBlock = attributedFormatBlock {
            attributedText = tryAttributedFormatBlock(value)
        } else if let tryFormatBlock = formatBlock {
            text = tryFormatBlock(value)
        } else {
            // check if counting with ints - cast to int
            if format.hasIntConversionSpecifier() {
                text = String(format: format, Int(value))
            } else {
                text = String(format: format, value)
            }
        }
    }

    private func setFormat(_ format: String) {
        self.format = format
        setTextValue(currentValue)
    }

    private func runCompletionBlock() {
        if let tryCompletionBlock = completionBlock {
            completionBlock = nil
            tryCompletionBlock()
        }
    }
}

extension String {
    func hasIntConversionSpecifier() -> Bool {
        // check if counting with ints
        // regex based on IEEE printf specification: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
        return nil != range(of: "%[^fega]*[diouxc]", options: [.regularExpression, .caseInsensitive])
    }
}
