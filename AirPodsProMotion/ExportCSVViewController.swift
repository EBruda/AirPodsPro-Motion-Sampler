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
    
    lazy var paceTextField: UITextField = {
        let textField = UITextField()
        textField.frame = CGRect(x: self.view.bounds.width / 4, y: self.view.bounds.maxY - 160,
                                 width: self.view.bounds.width / 2, height: 40)
        textField.placeholder = "Enter desired pace"
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.addTarget(self, action: #selector(paceEntered), for: .editingDidEndOnExit)
        return textField
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
    
    // AirPods Pro => APP :)
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
        view.addSubview(paceTextField)
        
        f.dateFormat = "yyyyMMdd_HHmmss"

        APP.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        write = false
        writer.close()
        APP.stopDeviceMotionUpdates()
        button.setTitle("Start", for: .normal)
    }
    
    func start() {
        APP.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {[weak self] motion, error  in
            guard let motion = motion, error == nil else { return }
                self?.writer.write(motion)
            self?.printData(motion)
        })
    }
    
    func stop() { APP.stopDeviceMotionUpdates() }
    
    @objc func Tap() {
        if write {
            write.toggle()
            writer.close()
            stop()
            button.setTitle("Start", for: .normal)
            AlertView.action(self, handler: {[weak self](_) in self?.viewCreatedFiles()}, animated: true)
        } else {
            guard APP.isDeviceMotionAvailable else {
                AlertView.alert(self, "Sorry", "Your device is not supported.")
                return
            }
            write.toggle()
            button.setTitle("Stop", for: .normal)
            let dir = FileManager.default.urls(
              for: .documentDirectory,
              in: .userDomainMask
            ).first!

            let now = Date()
            let filename = f.string(from: now) + "_motion.csv"
            let fileUrl = dir.appendingPathComponent(filename)
            writer.open(fileUrl)
            start()
        }
    }
    
    @objc func paceEntered() {
        if let pace = paceTextField.text, !pace.isEmpty {
            textView.text = "Desired Pace: \(pace)\n\n" + textView.text
        }
    }
    
    func printData(_ data: CMDeviceMotion) {
        self.textView.text = """
            Attitude:
                pitch: \(data.attitude.pitch)
                roll: \(data.attitude.roll)
                yaw: \(data.attitude.yaw)
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
    
    func viewCreatedFiles() {
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
