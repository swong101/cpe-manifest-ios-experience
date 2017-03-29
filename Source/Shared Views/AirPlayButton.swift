//
//  AirPlayButton.swift
//

import UIKit
import MediaPlayer

class AirPlayButton: MPVolumeView {

    private struct Constants {
        static let KeyAreWirelessRoutesAvailable = "areWirelessRoutesAvailable"
    }

    private var AirPlayButtonWirelessRoutesObservationContext = 1
    private var isObserving = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.showsVolumeSlider = false
        self.sizeToFit()

        if let templatedImage = (self.subviews.last as? UIButton)?.image(for: .selected)?.withRenderingMode(.alwaysTemplate) {
            self.setRouteButtonImage(templatedImage, for: .normal)
            self.setRouteButtonImage(templatedImage, for: .highlighted)
            self.setRouteButtonImage(templatedImage, for: .selected)
        }

    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &AirPlayButtonWirelessRoutesObservationContext {
            NotificationCenter.default.post(name: .availableWirelessRoutesDidChange, object: nil)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if newSuperview != nil {
            if !isObserving {
                self.addObserver(self, forKeyPath: Constants.KeyAreWirelessRoutesAvailable, options: .new, context: &AirPlayButtonWirelessRoutesObservationContext)
                isObserving = true
            }
        } else {
            self.removeObserver(self, forKeyPath: Constants.KeyAreWirelessRoutesAvailable)
            isObserving = false
        }
    }

}
