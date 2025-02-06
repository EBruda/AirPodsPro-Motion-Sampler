//
//  ExportCSV.swift
//  AirPodsProMotion
//
//  Created by Yoshio on 2020/11/10.
//

import Foundation
import UIKit
import CoreMotion

class ExportCSVViewController: UIViewController, CMHeadphoneMotionManagerDelegate {
    
    lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: self.view.bounds.width / 4, y: self.view.bounds.maxY - 100,
                              width: self.view.bounds.width / 2, height: 50)
        button.setTitle("Start",for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        button.layer.cornerRadius = 10
        button.backgroundColor = .systemBlue
        button.addTarget(self, action: #selector(Tap), for: .touchUpInside)
        
        return button
    }()
    
    lazy var textView: UITextView = {
        let view = UITextView()
        view.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                            y: self.view.bounds.minY + (self.view.bounds.height / 6),
                            width: self.view.bounds.width * 0.8, height: self.view.bounds.height - 300)
        view.text = "Press the start button below to start recording."
        view.font = view.font?.withSize(14)
        view.isEditable = false
        return view
    }()
    
    
    //AirPods Pro => APP :)
    let APP = CMHeadphoneMotionManager()
    
    let writer = CSVWriter()
    let f = DateFormatter()
    
    var write: Bool = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Information View"
        view.backgroundColor = .systemBackground
        view.addSubview(button)
        view.addSubview(textView)
        
        f.dateFormat = "yyyyMMdd_HHmmss"

        APP.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        write = false
        writer.close()
        APP.stopDeviceMotionUpdates()
        button.setTitle("Start", for: .normal)
    }


@objc func Tap() {
    if write {
        write.toggle()
        writer.close()
        stop()
        button.setTitle("Start", for: .normal)
        AlertView.action(self, handler: { [weak self] _ in self?.viewCreatedFiles() }, animated: true)
    } else {
        guard APP.isDeviceMotionAvailable else {
            AlertView.alert(self, "Sorry", "Your device is not supported.")
            return
        }
        
        // Call start() to prompt user for pace before recording begins
        start()
    }
}


    func start() {
    let alert = UIAlertController(
        title: "Enter Desired Pace",
        message: "Specify your pace (in mph)",
        preferredStyle: .alert
    )

    alert.addTextField { textField in
        textField.placeholder = "Enter pace here..."
    }

    let startAction = UIAlertAction(title: "Start", style: .default) { [weak self] _ in
        guard let self = self, let pace = alert.textFields?.first?.text, !pace.isEmpty else { return }

        // Display selected pace in textView
        DispatchQueue.main.async {
            self.textView.text = "Recording started with pace: \(pace)\n\n" + self.textView.text
        }

        // Toggle writing state **after user input**
        self.write = true
        self.button.setTitle("Stop", for: .normal)

        // Prepare file for writing
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let now = Date()
        let filename = self.f.string(from: now) + "_motion.csv"
        let fileUrl = dir.appendingPathComponent(filename)
        self.writer.open(fileUrl)

        // Start motion updates
        self.APP.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { motion, error in
            guard let motion = motion, error == nil else { return }
            self.writer.write(motion)
            self.printData(motion)
        })
    }

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

    alert.addAction(startAction)
    alert.addAction(cancelAction)

    // Present the alert before starting motion updates
    DispatchQueue.main.async {
        self.present(alert, animated: true, completion: nil)
    }
}


    func stop() { APP.stopDeviceMotionUpdates() }
    

    func printData(_ data: CMDeviceMotion) {
        self.textView.font = UIFont.systemFont(ofSize: 18) // Set larger font size
        self.textView.text =  """
            Gravitational Acceleration:
                x: \(data.gravity.x)
                y: \(data.gravity.y)
                z: \(data.gravity.z)
            Rotation Rate:
                x: \(data.rotationRate.x)
                y: \(data.rotationRate.y)
                z: \(data.rotationRate.z)
            Acceleration:
                x: \(data.userAcceleration.x)
                y: \(data.userAcceleration.y)
                z: \(data.userAcceleration.z)
            """

    }
    
    func viewCreatedFiles()
    {
        guard let dir = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first,
              let components = NSURLComponents(url: dir, resolvingAgainstBaseURL: true) else { return }
        components.scheme = "shareddocuments"
        if let sharedDocuments = components.url {
            UIApplication.shared.open(sharedDocuments, options: [:])
        } else {
            AlertView.warning(self)
        }
    }
}
