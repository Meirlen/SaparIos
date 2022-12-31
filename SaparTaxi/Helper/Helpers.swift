//
//  Helpers.swift
//
//  Created by Max on 29.07.2022.
//

import UIKit

typealias EmptyBlock = ()->()
typealias ResultBlock = (Bool)->()

class Helpers: NSObject {

}

extension UIViewController {
    class func loadFromStoryboard(name: String) -> Self? {
        return loadFromStoryboard(name: name, identifier: nil)
    }
    
    class func loadFromStoryboard(name: String, identifier: String?) -> Self? {
        let sb = UIStoryboard(name: name, bundle: nil)
        let iden = identifier ?? String(describing: self)
        let vc = sb.instantiateViewController(identifier: iden) as? Self
        return vc
    }    
}

extension DispatchQueue {
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
}

extension UIScreen {
    static var width: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    static var height: CGFloat {
        return UIScreen.main.bounds.height
    }
  }

extension UIView {
    //constraints
    
    var x: CGFloat {
        return frame.origin.x
    }
    var width: CGFloat {
        return bounds.size.width
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension UIView {
    func pinSubview(_ view: UIView, insets: UIEdgeInsets) {
        view.translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -insets.left).isActive = true
        topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom).isActive = true
    }
}

extension CALayer {
    var borderUIColor: UIColor? {
        get {
            if let color = borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            borderColor = newValue?.cgColor
        }
    }
}

