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
    
    @IBOutlet weak var gpsButton: UIButton?
    @IBOutlet weak var barView: UIView?
    @IBOutlet weak var infoBarView: UIView?
    @IBOutlet weak var heightInfoView: NSLayoutConstraint?
    
    @IBOutlet weak var setOrderView: UIView?
    @IBOutlet weak var resultPriceView: UIView?
    @IBOutlet weak var buttonOrderView: UIView?
    @IBOutlet weak var whereLabel: UILabel?
    @IBOutlet weak var whereView: UIView?
    @IBOutlet weak var whereNameLabel: UILabel?
    @IBOutlet weak var whereDescrLabel: UILabel?
    @IBOutlet weak var whereButton: UIButton?
    @IBOutlet weak var entranceButton: UIButton?
    
    @IBOutlet weak var finishLabel: UILabel?
    @IBOutlet weak var finishView: UIView?
    @IBOutlet weak var finishNameLabel: UILabel?
    @IBOutlet weak var finishDescrLabel: UILabel?
    @IBOutlet weak var finishButton: UIButton?
    @IBOutlet weak var plusAddressButton: UIButton?
    
    @IBOutlet weak var economView: UIView?
    @IBOutlet weak var comfortView: UIView?
    @IBOutlet weak var calculatePaymentButton: UIButton?
    
    @IBOutlet weak var priceButton: UIButton?
    
    @IBOutlet weak var pinView: UIImageView?
    @IBOutlet weak var addressLabel: UILabel?
    
    @IBOutlet weak var addressActivity: UIActivityIndicatorView?
    @IBOutlet weak var darkenedView: UIView?
    @IBOutlet weak var finishAddressesTableView: UITableView?
    @IBOutlet weak var heightViewTableView: NSLayoutConstraint?

    @IBOutlet weak var headerView: UIView?
    
    private var mapView: MapView!
    
    private var coordinate: CLLocationCoordinate2D?
    private func updateCoordinate(coord: CLLocationCoordinate2D, moveCamera: Bool) {
        guard coord != coordinate else { return }
        coordinate = coord
        if moveCamera {
            let frame = pinView?.superview?.frame ?? view.bounds
            let padding = UIEdgeInsets(top: frame.minY, left: 0, bottom: view.bounds.maxY - frame.maxY, right: 0)
            let options = CameraOptions(center: coordinate, padding: padding, zoom: 15)
            skipCameraMove = true
            mapView.mapboxMap.setCamera(to: options)
        }
        geocodeCurrentCoordinate()
    }
    private var coordinateTimer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    private var skipCameraMove = false
    
    var order = Order()
    
    var startAddress: Location? {
        get {
            return order.startLocation
        }
        set {
            order.startLocation = newValue
        
            whereLabel?.isHidden = (newValue != nil)
            whereView?.isHidden = (newValue == nil)
            whereNameLabel?.text = startAddress?.address
            whereDescrLabel?.text = startAddress?.desc
            
            if let coord = newValue?.coordinate {
                updateCoordinate(coord: coord, moveCamera: true)
            }
            
            requestAndDrawRoute()
            price = 0
        }
    }
    
    var finishAddresses: [Location] {
        get {
            return order.destinations
        }
        set {
            order.destinations = newValue
            
            let count = finishAddresses.count
            plusAddressButton?.isHidden = count >= 3
            
            calculatePaymentButton?.isEnabled = count > 0
            calculatePaymentButton?.alpha = count > 0 ? 1 : 0.6
            
            gpsButton?.isHidden = count > 0
            finishLabel?.isHidden = count > 0
            finishView?.isHidden = count == 0
            let addresses = finishAddresses.map({$0.address}).joined(separator: ", ")
            finishNameLabel?.text = addresses
            finishDescrLabel?.text = finishAddresses.first?.desc
            
            pinView?.superview?.isHidden = count > 0
            
            requestAndDrawRoute()
            if count == 0, let coord = startAddress?.coordinate {
                coordinate = nil
                updateCoordinate(coord: coord, moveCamera: true)
            }
            
            price = 0
            
            finishAddressesTableView?.reloadData()
        }
    }
    
    var price: Double {
        get {
            return order.price
        }
        set {
            order.price = newValue
            reloadInfoBar()
            priceButton?.setTitle(String(format: "%.0f", newValue) + " ₸", for: .normal)
        }
    }
    
    let indentifire = "AddressCell"
    
    var amountCompanion: Int?
    
    var state: State = .open
    var runningAnimators: [UIViewPropertyAnimator] = []
    var viewOffset: CGFloat = 0
    let heightTableView: CGFloat = 200
    let heightCellTableView: CGFloat = 44
    
    //MARK: -
    
    deinit {
        coordinateTimer = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        
        reloadInfoBar()
        
        mapView = MapView(frame: view.bounds, mapInitOptions: MapInitOptions())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(mapView, at: 0)
        
        mapView.mapboxMap.onEvery(event: .cameraChanged, handler: { [weak self] event in
            if self?.skipCameraMove == true {
                self?.skipCameraMove = false
                return
            }
            self?.setupCoordinateTimer()
        })
        
        addRecognizer()
        setupBarView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        heightViewTableView?.constant = 0
        if startAddress == nil {
            updateLocation()
        }
    }
    
    //MARK: - Actions
    
    @IBAction func getFreshLocation() {
        updateLocation()
    }
    
    @IBAction func setStart(_ sender: UIButton) {
        pushScreenSearch(start: true)
    }
    
    @IBAction func setFinish(_ sender: UIButton) {
        if finishAddresses.count == 0 {
            pushScreenSearch(start: false)
        }
        else if finishAddresses.count > 1 {
            showAllAddresses()
        }
    }
    
    @IBAction func addFinishAddresses(_ sender: UIButton) {
        pushScreenSearch(start: false)
    }
    
    func pushScreenSearch(start: Bool) {
        if let screen = SearchViewController.loadFromStoryboard(name: "Main") {
            screen.completion = { [weak self] address in
                if start {
                    self?.startAddress = address
                }
                else {
                    self?.finishAddresses.append(address)
                }
            }
            if start {
                screen.location = order.startLocation
            }
            navigationController?.pushViewController(screen, animated: true)
        }
    }
    
    @IBAction func pushScreenPayment() {
        guard let startLocation = order.startLocation else { return }
        if let screen = PaymentViewController.loadFromStoryboard(name: "Main") {
            screen.completion = { [weak self] price in
                if let pr = price?.price {
                    self?.price = pr
                    self?.amountCompanion = price?.amountCompanion
                }
            }
            var arrLoc = [Location]()
            arrLoc = finishAddresses
            arrLoc.insert(startLocation, at: 0)
            screen.arrLoc = arrLoc
            
            navigationController?.pushViewController(screen, animated: false)
        }
    }
    
    @IBAction func setTypeEconom(_ sender: UIButton) {
        economView?.backgroundColor = UIColor(named: "main_background")
        comfortView?.backgroundColor = .clear
    }
    
    @IBAction func setTypeComfort(_ sender: UIButton) {
        economView?.backgroundColor = .clear
        comfortView?.backgroundColor = UIColor(named: "main_background")
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
        
        if coordinate == startAddress?.coordinate {
            addressLabel?.text = startAddress?.address
            addressLabel?.isHidden = false
            addressActivity?.isHidden = true
            return
        }
        
        addressLabel?.isHidden = true
        addressActivity?.isHidden = false
        GeocodingService.getAddress(coordinate: coordinate) { [weak self] coord, address in
            guard let self = self, self.coordinate == coord else { return }
            let addr = address ?? GeocodingService.addressPlaceholder
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
        guard finishAddresses.count == 0 else { return }
        
        let point = CGPoint(x: pinView.frame.midX, y: pinView.frame.maxY)
        let mapPoint = mapView.convert(point, from: pinContainer)
        let coord = mapView.mapboxMap.coordinate(for: mapPoint)
        updateCoordinate(coord: coord, moveCamera: false)
    }
    
    //MARK: - Route
    
    private func requestAndDrawRoute() {
        let dest = finishAddresses
        guard let start = startAddress, dest.count > 0 else {
            addLine(coordinates: [])
            addCircleAnnotations(coordinates: [])
            return
        }
        
        var locations = [start]
        locations.append(contentsOf: dest)
        
        OpenStreetMapService.getRoute(locations: locations) { [weak self] coordinates in
            self?.drawRoute(coordinates: coordinates)
        }
    }
    
    private func drawRoute(coordinates: [CLLocationCoordinate2D]) {
        addLine(coordinates: coordinates)
        addCircleAnnotations(coordinates: coordinates)
        zoomMapToFit(coordinates: coordinates)
    }
    
    private func zoomMapToFit(coordinates: [CLLocationCoordinate2D]) {
        let lats = coordinates.map({$0.latitude})
        let lons = coordinates.map({$0.longitude})
        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(), let maxLon = lons.max() else { return }
        
        let rect = pinView?.superview?.frame ?? mapView.bounds
        let bounds = CoordinateBounds(southwest: CLLocationCoordinate2D(latitude: minLat, longitude: minLon), northeast: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon))
        let padding = UIEdgeInsets(top: 50, left: 20, bottom: mapView.bounds.maxY - rect.maxY, right: 20)
        let camera = mapView.mapboxMap.camera(for: bounds, padding: padding, bearing: 0, pitch: 0)
        mapView.mapboxMap.setCamera(to: camera)
    }
    
    private func addLine(coordinates: [CLLocationCoordinate2D]) {
        let manager = mapView.annotations.makePolylineAnnotationManager(id: "line")
        guard coordinates.count > 1 else {
            manager.annotations = []
            return
        }
        var line = PolylineAnnotation(lineCoordinates: coordinates)
        line.lineColor = StyleColor(UIColor(named: "main_blue") ?? .blue)
        line.lineWidth = 5
        manager.annotations = [line]
    }
    
    private func addCircleAnnotations(coordinates: [CLLocationCoordinate2D]) {
        
        let manager = mapView.annotations.makePointAnnotationManager(id: "point")
//        let img = UIImage(systemName: "mappin")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        let img = UIImage(named: "pin_icon")
        guard let first = coordinates.first, let last = coordinates.last, let img = img else {
            manager.annotations = []
            return
        }
        
        var startAnnotation = PointAnnotation(coordinate: first)
        startAnnotation.image = .init(image: img, name: "start_pin")
        startAnnotation.iconAnchor = .bottom
        startAnnotation.iconColor = StyleColor(UIColor.red)

        var endAnnotation = PointAnnotation(coordinate: last)
        endAnnotation.image = .init(image: img, name: "end_pin")
        endAnnotation.iconAnchor = .bottom
        
        manager.annotations = [startAnnotation, endAnnotation]
    }
    
    //MARK: - Bottom bar
    
    func layoutBottomBar() {
        guard let stackView = buttonOrderView?.superview as? UIStackView else { return }
        let views = stackView.arrangedSubviews.filter({$0.isHidden == false})
        let heights = views.map({$0.bounds.height})
        viewOffset = heights.reduce(0, +) + CGFloat(heights.count - 1) * stackView.spacing + 16
        if state == .open {
            heightInfoView?.constant = viewOffset
        }
    }
    
    func reloadInfoBar() {
        let havePrice = (price > 0)
        setOrderView?.isHidden = havePrice
        buttonOrderView?.isHidden = !havePrice
        resultPriceView?.isHidden = !havePrice
        layoutBottomBar()
    }
    
    private func setupBarView() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onDrag(_:)))
        self.barView?.addGestureRecognizer(panGesture)
        
        if let img = UIImage(named: "bacground_header_bar") {
            headerView?.backgroundColor = UIColor(patternImage: img)
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
            commitBarAnimation()
        default:
            break
        }
    }
    
    private func commitBarAnimation() {
        runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
    }
    
    //MARK: - Destinations table view
    
    func addRecognizer() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        self.view.addGestureRecognizer(swipeDown)
    }
    
    func showAllAddresses() {
        heightViewTableView?.constant = self.heightCellTableView * CGFloat(self.finishAddresses.count)
        UIView.animate(withDuration: 0.5, animations: {
            self.darkenedView?.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func respondToSwipeGesture() {
        heightViewTableView?.constant = 0
        UIView.animate(withDuration: 0.5) {
            self.darkenedView?.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
}

extension MapViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return finishAddresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indentifire, for: indexPath)
        guard let listCell = cell as? AddressCell else { return cell }
        
        let address = finishAddresses[indexPath.row]
        listCell.addressNameLabel?.text = address.address
        listCell.addressDiscrLabel?.text = address.desc
        listCell.deleteButton?.tag = indexPath.row
        listCell.deleteButton?.removeTarget(self, action: nil, for: .touchUpInside)
        listCell.deleteButton?.addTarget(self, action:#selector(deleteCell(_:)), for: .touchUpInside)

        return cell
    }
    
    @objc func deleteCell(_ sender: UIButton){
        finishAddresses.remove(at: sender.tag)
        finishAddressesTableView?.reloadData()
    }
}

class AddressCell: UITableViewCell {
    @IBOutlet weak var addressNameLabel: UILabel?
    @IBOutlet weak var addressDiscrLabel: UILabel?
    @IBOutlet weak var deleteButton: UIButton?
}
