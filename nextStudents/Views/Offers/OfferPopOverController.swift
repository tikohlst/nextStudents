//
//  OfferPopOverController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit

class OfferPopOverController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterControl: UISegmentedControl!
    
    // MARK: - Variables
    var offers: [Offer]?
    var filteredOffers: [Offer]?
    weak var delegate: OfferFilterControllerDelegate?
    
    // MARK: - UIViewController events
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        filterControl.addTarget(self, action:
            #selector(filterOffers), for: .valueChanged)
        filterControl.addTarget(self, action: #selector(setDelegate), for: .valueChanged)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let fittedSize = filterView?.sizeThatFits(UIView.layoutFittingCompressedSize) {
            preferredContentSize = CGSize(width: fittedSize.width + 30, height: fittedSize.height + 30)
        }
    }
    
    // MARK: - Methods
    @objc private func filterOffers() {
        
        switch filterControl.selectedSegmentIndex {
        case 0:
            // Biete
            filteredOffers = offers?.filter({ offer -> Bool in
                offer.type == "Biete"
            })
        case 2:
            // Suche
            filteredOffers = offers?.filter({ offer -> Bool in
                offer.type == "Suche"
            })
        default:
            filteredOffers = offers
        }
    }
    
    @objc private func setDelegate() {
        if let delegate = delegate {
            delegate.forward(data: filteredOffers!)
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
protocol OfferFilterControllerDelegate: NSObjectProtocol {
    func forward(data: [Offer])
}
