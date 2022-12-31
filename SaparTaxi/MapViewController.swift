//
//  ViewController.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import UIKit
import MapboxMaps

enum State {
    case closed
    case open
    
    var apposite: State {
        return self == .open ? .closed : .open
    }
}

class MapViewController: UIViewController {
    
    @IBOutlet weak var barView: UIView?
    @IBOutlet weak var heightInfoView: NSLayoutConstraint?    

    private var mapView: MapView!
    var state: State = .open
    var runningAnimators: [UIViewPropertyAnimator] = []
    var viewOffset: CGFloat = 326
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        
        mapView = MapView(frame: view.bounds, mapInitOptions: MapInitOptions())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(mapView, at: 0)
        
        setupBarView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLocation()        
    }
    
    //MARK: -
    
    @IBAction func getFreshLocation() {
        updateLocation()
    }
    
    @IBAction func pushScreenSearch() {
        let vc = navigationController
        if let screen = SearchViewController.loadFromStoryboard(name: "Main") {
            vc?.pushViewController(screen, animated: true)
        }
    }
    
    
    private func updateLocation() {
        LocationService.shared.requestLocation { [weak self] location in
            if let coord = location?.coordinate {
                let options = CameraOptions(center: coord)
                self?.mapView.mapboxMap.setCamera(to: options)
            }
        }
    }
    
    func animateView(to state: State, duration: TimeInterval )  {
        
        guard runningAnimators.isEmpty else { return }
        
        let basicAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeIn, animations: nil)
         
        basicAnimator.addAnimations {
            switch state {
            case .open:
                self.heightInfoView?.constant = self.viewOffset
            case .closed:
                self.heightInfoView?.constant = 0
            }
            self.view.layoutIfNeeded()
        }
        basicAnimator.scrubsLinearly = false
        
        basicAnimator.addCompletion { (animator) in
            self.runningAnimators.removeAll()
            self.state = self.state.apposite
        }
        
        runningAnimators.append(basicAnimator)
    }
    
    func setupBarView() {
        self.heightInfoView?.constant = viewOffset
        self.view.layoutIfNeeded()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onDrag(_:)))
        self.barView?.addGestureRecognizer(panGesture)
    }

    @objc func onDrag(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            animateView(to: state.apposite, duration: 0.4)
        case .changed:
            let translation = gesture.translation(in: barView)
            let fraction = abs(translation.y / viewOffset)
            
            runningAnimators.forEach { (animator) in
                animator.fractionComplete = fraction
                
            }
        case .ended:
            runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
        default:
            break
        }
    }
}

