//
//  MapViewController.swift
//  SaparTaxi
//
//  Created by Vova Home on 30.12.2022.
//

import UIKit
import MapboxMaps
import MapboxCommon

enum State {
    case closed
    case open
    
    var apposite: State {
        return self == .open ? .closed : .open
    }
}

class MapViewController: UIViewController {
    
    @IBOutlet weak var barView: UIView?
    @IBOutlet weak var infoBarView: UIView?
    @IBOutlet weak var heightInfoView: NSLayoutConstraint?
    @IBOutlet weak var whereLabel: UILabel?
    @IBOutlet weak var whereView: UIView?
    @IBOutlet weak var whereNameLabel: UILabel?
    @IBOutlet weak var whereDescrLabel: UILabel?
    @IBOutlet weak var finishLabel: UILabel?
    @IBOutlet weak var finishView: UIView?
    @IBOutlet weak var finishNameLabel: UILabel?
    @IBOutlet weak var finishDescrLabel: UILabel?
    
    
    @IBOutlet weak var pinView: UIImageView?
    @IBOutlet weak var addressLabel: UILabel?
    
    @IBOutlet weak var addressActivity: UIActivityIndicatorView?
    @IBOutlet weak var darkenedView: UIView?
    @IBOutlet weak var heightViewTableView: NSLayoutConstraint?    

    private var mapView: MapView!
    
    private var coordinate: CLLocationCoordinate2D?
    private func updateCoordinate(coord: CLLocationCoordinate2D, moveCamera: Bool) {
        coordinate = coord
        if moveCamera {
            let frame = pinView?.superview?.frame ?? view.bounds
            let padding = UIEdgeInsets(top: frame.minY, left: 0, bottom: view.bounds.maxY - frame.maxY, right: 0)
            let options = CameraOptions(center: coordinate, padding: padding, zoom: 15)
            mapView.mapboxMap.setCamera(to: options)
        }
        geocodeCurrentCoordinate()
    }
    private var coordinateTimer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    var order = Order()
    
    var startAddress: Location? {
        get {
            return order.startLocation
        }
        set {
            order.startLocation = newValue
        
            whereLabel?.isHidden = true
            whereView?.isHidden = false
            whereNameLabel?.text = startAddress?.address
            whereDescrLabel?.text = startAddress?.desc
        }
    }
    
    var finishAddresses: [Location] {
        get {
            return order.destinations
        }
        set {
            order.destinations = newValue
            
            finishLabel?.isHidden = true
            finishView?.isHidden = false
            finishNameLabel?.text = finishAddresses.first?.address
            finishDescrLabel?.text = finishAddresses.first?.desc
        }
    }
    
    var state: State = .open
    var runningAnimators: [UIViewPropertyAnimator] = []
    var viewOffset: CGFloat = 0
    let heightTableView: CGFloat = 200
    
    //MARK: -
    
    deinit {
        coordinateTimer = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        
        guard let infoBarViewHeight = infoBarView?.frame.height else { return }
        viewOffset = infoBarViewHeight
        
        mapView = MapView(frame: view.bounds, mapInitOptions: MapInitOptions())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(mapView, at: 0)
        
        mapView.mapboxMap.onEvery(event: .cameraChanged, handler: { [weak self] event in
            self?.setupCoordinateTimer()
        })
        
        setupBarView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        heightViewTableView?.constant = 0
        updateLocation()        
    }
    
    //MARK: - Actions
    
    @IBAction func getFreshLocation() {
        updateLocation()
    }
    
    @IBAction func pushScreenSearch() {
        if let screen = SearchViewController.loadFromStoryboard(name: "Main") {
            screen.completion = { [weak self] address in
                if self?.startAddress == nil {
                    self?.startAddress = address
                }
                else {
                    self?.finishAddresses.append(address)
                }
            }
            screen.location = order.startLocation
            navigationController?.pushViewController(screen, animated: true)
        }
    }
    
    @IBAction func pushScreenPayment() {
        if let screen = PaymentViewController.loadFromStoryboard(name: "Main") {
            navigationController?.pushViewController(screen, animated: false)
        }
    }
    
    //MARK: -
    
    private func updateLocation() {
        LocationService.shared.requestLocation { [weak self] location in
            if let coord = location?.coordinate {
                self?.updateCoordinate(coord: coord, moveCamera: true)
            }
        }
    }
    
    private func geocodeCurrentCoordinate() {
        guard let coordinate = coordinate else { return }
        addressLabel?.isHidden = true
        addressActivity?.isHidden = false
        GeocodingService.getAddress(coordinate: coordinate) { [weak self] coord, address in
            guard let self = self, self.coordinate == coord else { return }
            let addr = address ?? "неизвестное место"
            self.addressLabel?.text = addr
            self.addressLabel?.isHidden = false
            self.addressActivity?.isHidden = true
            
            self.startAddress = Location(coordinate: coord, address: addr, desc: "")
        }
    }
    
    private func setupCoordinateTimer() {
        coordinateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] timer in
            self?.obtainCoordinateUnderPin()
        })
    }
    
    private func obtainCoordinateUnderPin() {
        guard let pinView = pinView, let pinContainer = pinView.superview else { return }
        
        let point = CGPoint(x: pinView.frame.midX, y: pinView.frame.maxY)
        let mapPoint = mapView.convert(point, from: pinContainer)
        let coord = mapView.mapboxMap.coordinate(for: mapPoint)
        updateCoordinate(coord: coord, moveCamera: false)
    }
    
    private func requestAndDrawRoute() {
        let loc1 = Location(coordinate: CLLocationCoordinate2D(latitude: 49.77490997, longitude: 73.13254547), address: "улица Язева, 10", desc: "улица Язева, 10")
        let loc2 = Location(coordinate: CLLocationCoordinate2D(latitude: 49.80342102, longitude: 73.08615875), address: "ЦУМ", desc: "ЦУМ")
//        order.startLocation
//        order.destinations
        OpenStreetMapService.getRoute(locations: [loc1, loc2]) { [weak self] coordinates in
            var line = PolylineAnnotation(lineCoordinates: coordinates)
            line.lineColor = StyleColor(.red)
            line.lineWidth = 5
            let manager = self?.mapView.annotations.makePolylineAnnotationManager()
            manager?.annotations = [line]
        }
    }
    
    //MARK: - Bottom bar
    
    private func setupBarView() {
        self.heightInfoView?.constant = viewOffset
        self.view.layoutIfNeeded()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onDrag(_:)))
        self.barView?.addGestureRecognizer(panGesture)
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
            self.obtainCoordinateUnderPin()
        }
        
        runningAnimators.append(basicAnimator)
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
    
    @IBAction func showAllAddresses(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.darkenedView?.alpha = 1
            self.darkenedView?.isHidden = false
            self.heightViewTableView?.constant = self.heightTableView
            self.view.layoutIfNeeded()
        })
    }
    
    
    //MARK: - 
    
    func addRecognizer() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        self.view.addGestureRecognizer(swipeDown)
    }
    
    @objc func respondToSwipeGesture() {
        UIView.animate(withDuration: 0.5, animations: {
            self.darkenedView?.alpha = 0
            self.heightViewTableView?.constant = 0
            self.view.layoutIfNeeded()
        }, completion:  {
           (value: Bool) in
            self.darkenedView?.isHidden = true
        })
    }
}

