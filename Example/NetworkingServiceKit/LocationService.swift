//
//  LocationService.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/25/17.
//
//

import Foundation
import CoreLocation
import MapKit
import NetworkingServiceKit

open class LocationAnnotation: NSObject, MKAnnotation {

    public var title: String?
    public var coordinate: CLLocationCoordinate2D

    public init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }
}

open class LocationService: AbstractBaseService {

    /// Maps a set of IndexPaths and TwitterSearchResult into LocationAnnotation by matching the ones with location data against Apple CLGeocoder
    ///
    /// - Parameters:
    ///   - visibleIndexes: a list of table indexes
    ///   - results: current list of search results
    ///   - completion: A list of location annotation for the search results that had valid locations
    public func geocodeTweets(on visibleIndexes: [IndexPath]?,
                              with results: [TwitterSearchResult],
                              completion: @escaping (_ annotations: [LocationAnnotation]) -> Void) {

        if let visibleIndexes = visibleIndexes, visibleIndexes.count > 0 {
            let flatVisibleIndexRows = visibleIndexes.flatMap { $0.row }
            let visibleSearchResults = results.enumerated().filter { index, result -> Bool in
                return flatVisibleIndexRows.contains(index) && !result.user.location.isEmpty
            }
            let visibleLocationResults = visibleSearchResults.flatMap {$0.element.user.location}

            var annotations = [LocationAnnotation]()
            let group = DispatchGroup()
            for locationName in visibleLocationResults {
                group.enter()
                CLGeocoder().geocodeAddressString(String(locationName), completionHandler: { placemark, _ in
                    if let placemark = placemark?.first,
                        let location = placemark.location {
                        annotations.append(LocationAnnotation(title: String(locationName), coordinate: location.coordinate))
                    }
                    group.leave()
                })
            }

            group.notify(queue: .main) {
                //All location requests done
                completion(annotations)
            }
        }

    }
}
