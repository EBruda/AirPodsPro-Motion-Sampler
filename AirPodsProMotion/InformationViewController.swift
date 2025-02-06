import UIKit
import CoreMotion
import CoreLocation

class InformationViewController: UIViewController, CLLocationManagerDelegate {

    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private var motionData: [(accelX: Double, accelY: Double, accelZ: Double, gyroX: Double, gyroY: Double, gyroZ: Double, latitude: Double?, longitude: Double?)] = []
    
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
    
    lazy var exportButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                              y: self.view.bounds.minY + (self.view.bounds.height * 0.6),
                              width: self.view.bounds.width * 0.8, height: 50)
        button.setTitle("Export CSV", for: .normal)
        button.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Motion Tracker"
        view.backgroundColor = .systemBackground
        view.addSubview(textView)
        view.addSubview(paceTextField)
        view.addSubview(exportButton)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

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
            let currentLocation = self.locationManager.location
            
            self.motionData.append((accel.x, accel.y, accel.z, gyro.x, gyro.y, gyro.z, currentLocation?.coordinate.latitude, currentLocation?.coordinate.longitude))
            
            let motionText = "Acceleration:\nX: \(accel.x)\nY: \(accel.y)\nZ: \(accel.z)\n\nGyroscope:\nX: \(gyro.x)\nY: \(gyro.y)\nZ: \(gyro.z)\n\nGPS:\nLatitude: \(currentLocation?.coordinate.latitude ?? 0)\nLongitude: \(currentLocation?.coordinate.longitude ?? 0)"
            
            self.updateTextView(motionText)
        }
    }

    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
        updateTextView("Motion tracking stopped.")
    }

    @objc private func exportButtonTapped() {
        exportMotionData()
    }

    private func exportMotionData() {
        let fileName = "motion_data.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var csvText = "AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ,Latitude,Longitude\n"
        
        for data in motionData {
            let line = "\(data.accelX),\(data.accelY),\(data.accelZ),\(data.gyroX),\(data.gyroY),\(data.gyroZ),\(data.latitude ?? 0),\(data.longitude ?? 0)\n"
            csvText.append(line)
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            print("CSV file saved at: \(path)")
        } catch {
            print("Failed to save CSV file: \(error.localizedDescription)")
        }
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateTextView("GPS Location:\nLatitude: \(location.coordinate.latitude)\nLongitude: \(location.coordinate.longitude)\n\n" + textView.text)
    }
}

