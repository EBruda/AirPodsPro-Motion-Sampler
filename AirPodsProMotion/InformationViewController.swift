import UIKit
import CoreMotion

class InformationViewController: UIViewController {

    private let pedometer = CMPedometer()

    lazy var textView: UITextView = {
        let view = UITextView()
        view.frame = CGRect(x: self.view.bounds.minX + (self.view.bounds.width / 10),
                            y: self.view.bounds.minY + (self.view.bounds.height / 6),
                            width: self.view.bounds.width * 0.8, height: self.view.bounds.height * 0.3)
        view.text = "Looking for AirPods Pro"
        view.font = UIFont.systemFont(ofSize: 18)
        view.isEditable = false
        view.textAlignment = .center
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Information View"
        view.backgroundColor = .systemBackground
        view.addSubview(textView)

        startPedometerUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPedometerUpdates()
    }

    private func startPedometerUpdates() {
        guard CMPedometer.isPaceAvailable() else {
            textView.text = "Pace data is not available on this device."
            return
        }

        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.textView.text = "Error fetching pedometer data."
                }
                return
            }

            DispatchQueue.main.async {
                if let pace = data.currentPace {
                    self.textView.text = "Current Pace: \(pace) steps/sec"
                } else {
                    self.textView.text = "Pace data is not available yet."
                }
            }
        }
    }

    private func stopPedometerUpdates() {
        pedometer.stopUpdates()
    }
}