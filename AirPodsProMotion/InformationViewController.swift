//
//  ViewController.swift
//  AirPodsProMotion
//
//  Created by Yoshio on 2020/09/22.
//

import UIKit
import CoreMotion

class InformationViewController: UIViewController, CMHeadphoneMotionManagerDelegate {

    lazy var textView: UITextView = {
        let view = UITextView()
        view.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                            y: self.view.bounds.minY + (self.view.bounds.height / 6),
                            width: self.view.bounds.width, height: self.view.bounds.height)
        view.text = "Looking for AirPods Pro"
        view.font = view.font?.withSize(14)
        view.isEditable = false
        return view
    }()
    
    
    
    //AirPods Pro => APP :)
    // let APP = CMHeadphoneMotionManager()
    let APP_2 = CMPedometer()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Information View"
        view.backgroundColor = .systemBackground
        view.addSubview(textView)
        
        
        APP_2.delegate = self
        
        // guard APP_2.isDeviceMotionAvailable else {
        //     AlertView.alert(self, "Sorry", "Your device is not supported.")
        //     textView.text = "Sorry, Your device is not supported."
        //     return
        // }
        
        guard CMPedometer.isPaceAvailable() else {
            print("Pace data is not available on this device.")
            return
        }
        // APP.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {[weak self] motion, error  in
        //     guard let motion = motion, error == nil else { return }
        //     self?.printData(motion)
        // })

        
        APP_2.startUpdates(from: Date()) { (data, error) in
            guard let data = data, error == nil else {
                print("Error fetching pedometer data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let pace = data.currentPace {
                print("Current Pace: \(pace) steps per second")
                self.textView.text = """
                    Pace: 
                        \(data.currentPace)
                    """
            } else {
                print("Pace data is not available yet.")
            }
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        APP.stopDeviceMotionUpdates()
        APP_2.stopDeviceMotionUpdates()
    }
    
}
