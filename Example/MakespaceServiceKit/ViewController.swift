//
//  ViewController.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 02/23/2017.
//  Copyright (c) 2017 Makespace Inc. All rights reserved.
//

import UIKit
import MapKit
import MakespaceServiceKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tweetsTableView: UITableView!
    private var currentResults:[TwitterSearchResult] = [TwitterSearchResult]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tweetsTableView.estimatedRowHeight = 85
        self.tweetsTableView.rowHeight = UITableViewAutomaticDimension
        self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld)
        self.mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 40.709540, longitude: -74.008078) //center in NYC
        //Do initial search 
        self.searchBar(searchBar, textDidChange: "Makespace")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TweetCell.self)) as? TweetCell {
            cell.load(with: currentResults[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let approachingBottomIndex = currentResults.count - 2
        if indexPath.row == approachingBottomIndex {
            let twitterSearchService = ServiceLocator.service(forType: TwitterSearchService.self)
            twitterSearchService?.searchNextRecentsPage(completion: { [weak self] results in
                self?.currentResults.append(contentsOf: results)
                self?.tweetsTableView.reloadData()
                self?.showTweetsLocationsOnMap()
            })
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        //this should be throtte
        let twitterSearchService = ServiceLocator.service(forType: TwitterSearchService.self)
        twitterSearchService?.searchRecents(by: searchText, completion: { [weak self] results in
            
            if let annotations = self?.mapView.annotations {
                self?.mapView.removeAnnotations(annotations)
            }
            self?.currentResults = results
            self?.tweetsTableView.reloadData()
            self?.showTweetsLocationsOnMap()
        })
    }
    
    func showTweetsLocationsOnMap()
    {
        let locationService = ServiceLocator.service(forType: LocationService.self)
        locationService?.geocodeTweets(on: tweetsTableView.indexPathsForVisibleRows,
                                       with: currentResults,
                                       completion: { annotations in
            annotations.forEach { self.mapView.addAnnotation($0) }
        })
    }
}
