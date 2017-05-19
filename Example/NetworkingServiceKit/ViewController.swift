//
//  ViewController.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 02/23/2017.
//  Copyright (c) 2017 Makespace Inc. All rights reserved.
//

import UIKit
import MapKit
import NetworkingServiceKit

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var mapView: MKMapView!
    @IBOutlet fileprivate weak var searchBar: UISearchBar!
    @IBOutlet fileprivate weak var tweetsTableView: UITableView!
    fileprivate var currentResults: [TwitterSearchResult] = [TwitterSearchResult]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tweetsTableView.estimatedRowHeight = 85
        tweetsTableView.rowHeight = UITableViewAutomaticDimension
        mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld)
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 40.709540, longitude: -74.008078) //center in NYC
        //Do initial search 
        searchBar(searchBar, textDidChange: "Makespace")
    }

    func showTweetsLocationsOnMap() {
        let locationService = ServiceLocator.service(forType: LocationService.self)
        locationService?.geocodeTweets(on: tweetsTableView.indexPathsForVisibleRows,
                                       with: currentResults,
                                       completion: { annotations in
            annotations.forEach { self.mapView.addAnnotation($0) }
        })
    }
}

extension ViewController: UISearchBarDelegate
{
    
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
}

extension ViewController: UITableViewDelegate, UITableViewDataSource
{
    
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
}
