//
//  FadeSegue.swift
//  Mindora final
//
//  Created by Navya on 12/11/25.
//

import UIKit

class FadeSegue: UIStoryboardSegue {

    override func perform() {
        let sourceVC = self.source
        let destinationVC = self.destination

        // Set the presentation style
        destinationVC.modalPresentationStyle = .fullScreen

        // Create fade transition animation
        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.6

        // Apply transition to the source view's window
        sourceVC.view.window?.layer.add(transition, forKey: nil)

        // Present the destination view controller without animation (animation is handled by CATransition)
        sourceVC.present(destinationVC, animated: false, completion: nil)
    }
}
