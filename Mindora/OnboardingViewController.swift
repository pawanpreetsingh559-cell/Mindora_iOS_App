//
//  OnboardingViewController.swift
//  Mindora final
//
//  Created by Navya  on 15/11/25.
//
import UIKit

class OnboardingViewController: UIViewController {

   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
