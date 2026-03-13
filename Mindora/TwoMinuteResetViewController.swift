//
//  TwoMinuteResetViewController.swift
//  Mindora final
//
//  Created by Navya  on 15/11/25.
//

import UIKit

class TwoMinuteResetViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var activity1View: UIView!
    @IBOutlet weak var activity2View: UIView!
    @IBOutlet weak var activity3View: UIView!
    @IBOutlet weak var activity4View: UIView!
    @IBOutlet weak var activity5View: UIView!
    @IBOutlet weak var activity6View: UIView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    // MARK: - Setup
    private func setupGestures() {
        addTap(to: activity1View, action: #selector(handleDeepBreathing))
        addTap(to: activity2View, action: #selector(handleCalmingSounds))
        addTap(to: activity3View, action: #selector(handleFingerRhythm))
        addTap(to: activity4View, action: #selector(handleShoulderDrop))
        addTap(to: activity5View, action: #selector(handleEyeRelaxation))
        addTap(to: activity6View, action: #selector(handleMeditation))
    }
    
    private func addTap(to view: UIView, action: Selector) {
        let tap = UITapGestureRecognizer(target: self, action: action)
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - Actions
    @objc private func handleDeepBreathing() {
        navigateToBreathing(name: "Deep Breathing", type: "breathing")
    }
    
    @objc private func handleCalmingSounds() {
        navigateToBreathing(name: "Calming Sounds", type: "calmingSounds")
    }
    
    @objc private func handleFingerRhythm() {
        navigateToBreathing(name: "Finger Rhythm", type: "fingerRhythm")
    }
    
    @objc private func handleShoulderDrop() {
        navigateToBreathing(name: "Shoulder Drop", type: "shoulderDrop")
    }
    
    @objc private func handleEyeRelaxation() {
        navigateToBreathing(name: "Eye Relaxation", type: "eyeRelaxation")
    }
    
    @objc private func handleMeditation() {
        navigateToBreathing(name: "Meditation", type: "meditation")
    }
    
    // MARK: - Navigation
    private func navigateToBreathing(name: String, type: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let breathingVC = storyboard.instantiateViewController(withIdentifier: "breathingVC") as? BreathingViewController {
            breathingVC.activityName = name
            breathingVC.exerciseType = type
            
            if let navigationController = self.navigationController {
                navigationController.pushViewController(breathingVC, animated: true)
            } else {
                breathingVC.modalPresentationStyle = .fullScreen
                self.present(breathingVC, animated: true)
            }
        }
    }
}
