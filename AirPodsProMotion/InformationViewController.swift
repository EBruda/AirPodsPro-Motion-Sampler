import UIKit
import CoreMotion

class InformationViewController: UIViewController {

    private let motionManager = CMMotionManager()
    
    lazy var textView: UITextView = {
        let view = UITextView()
        view.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                            y: self.view.bounds.minY + (self.view.bounds.height / 6),
                            width: self.view.bounds.width * 0.8, height: self.view.bounds.height * 0.3)
        view.text = "Starting motion tracking..."
        view.font = UIFont.systemFont(ofSize: 18)
        view.isEditable = false
        view.textAlignment = .center
        return view
    }()
    
    lazy var paceTextField: UITextField = {
        let textField = UITextField()
        textField.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                                 y: self.view.bounds.minY + (self.view.bounds.height / 2),
                                 width: self.view.bounds.width * 0.8, height: 40)
        textField.placeholder = "Enter desired pace"
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.addTarget(self, action: #selector(paceEntered), for: .editingDidEndOnExit)
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Motion Tracker"
        view.backgroundColor = .systemBackground
        view.addSubview(textView)
        view.addSubview(paceTextField)

        startMotionUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopMotionUpdates()
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            updateTextView("Motion data is not available on this device.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 updates per second
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else {
                if let error = error {
                    self?.updateTextView("Error: \(error.localizedDescription)")
                }
                return
            }
            
            let accel = motion.userAcceleration
            let gyro = motion.rotationRate
            let motionText = "Acceleration:\nX: \(accel.x)\nY: \(accel.y)\nZ: \(accel.z)\n\nGyroscope:\nX: \(gyro.x)\nY: \(gyro.y)\nZ: \(gyro.z)"
            
            self.updateTextView(motionText)
        }
    }

    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        updateTextView("Motion tracking stopped.")
    }

    private func updateTextView(_ text: String) {
        DispatchQueue.main.async {
            self.textView.text = text
        }
    }
    
    @objc private func paceEntered() {
        if let pace = paceTextField.text, !pace.isEmpty {
            updateTextView("Desired Pace: \(pace)\n\n" + textView.text)
        }
    }
}
