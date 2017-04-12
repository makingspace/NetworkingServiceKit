//
//  OpsService.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/7/17.
//
//

import Foundation

public enum MakespacePath : String
{
    case places = "places"
    case containers = "containers"
    case containerSet = "container-sets"
    case jobs = "jobs"
    case files = "files"
    case tasks = "tasks"
    case events = "events"
    case staff = "staff"
    case accounts = "accounts"
    case signatures = "signatures"
    case fulfillers = "fulfillers"
    case questions = "question_answers"
}


public enum JobStatusType: String
{
    case created = "CREATED"
    case started = "STARTED"
    case completed = "COMPLETED"
    case canceled = "CANCELED"
}

open class OpsService: AbstractBaseService {
    
    // MARK: - Sets
    
    public func getContainerSet(withLocator locator: String,
                                success successBlock: @escaping SuccessResponseBlock,
                                error errorBlock: @escaping ErrorResponseBlock) {
        request(path: "\(MakespacePath.containerSet.rawValue)/\(locator)",
            method: .get,
            with: [String: Any](),
            paginated: true,
            success: successBlock,
            failure: errorBlock)
    }
    
    public func updateContainerSet(withLocator locator: String,
                                   length: Double,
                                   width: Double,
                                   height: Double,
                                   success successBlock: @escaping SuccessResponseBlock,
                                   error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if length != 0 {
            params["length"] = length
        }
        if width != 0 {
            params["width"] = width
        }
        if height != 0 {
            params["height"] = height
        }
        request(path: "\(MakespacePath.containerSet.rawValue)/\(locator)",
            method: .patch,
            with: params,
            paginated: true,
            success: successBlock,
            failure: errorBlock)
    }
    // MARK: - Places
    
    public func getPlacesWithParameters(_ parameters: [String: Any],
                                        paginated: Bool = true,
                                        success successBlock: @escaping SuccessResponseBlock,
                                        error errorBlock: @escaping ErrorResponseBlock) {
        request(path: MakespacePath.places.rawValue,
                method: .get,
                with: parameters,
                paginated: paginated,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getPlacesWithLatitude(_ lat: Double,
                                      longitude lon: Double,
                                      parentXid: String?,
                                      page: Int?,
                                      paginated: Bool = true,
                                      success successBlock: @escaping SuccessResponseBlock,
                                      error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        params["lat"] = lat
        params["lon"] = lon
        
        if let parentXid = parentXid, !parentXid.isEmpty {
            params["parent"] = parentXid
        }
        if let page = page {
            params["page"] = page
        }
        self.getPlacesWithParameters(params, paginated: paginated, success: successBlock, error: errorBlock)
    }
    
    public func getPlacesWithLocator(_ locator: String,
                                     paginated: Bool = true,
                                     success successBlock: @escaping SuccessResponseBlock,
                                     error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if locator != "" {
            params["marker_locator"] = locator
        }
        request(path: MakespacePath.places.rawValue,
                method: .get,
                with: params,
                paginated: paginated,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func updatePlace(withPlaceXid placeXid: String,
                            locator updatedLocator: String,
                            success successBlock: @escaping SuccessResponseBlock,
                            error errorBlock: @escaping ErrorResponseBlock) {
        let params: [String: Any] = ["marker": updatedLocator]
        request(path: "\(MakespacePath.places.rawValue)/\(placeXid)",
            method: .patch,
            with: params,
            paginated: true,
            success: successBlock,
            failure: errorBlock)
    }
    // MARK: - Jobs
    
    public func getJobsWithFacilityXid(_ facilityXid: String,
                                       status: JobStatusType,
                                       success successBlock: @escaping SuccessResponseBlock,
                                       error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if facilityXid.characters.count > 0 {
            params["facility"] = facilityXid
        }
        params["status"] = status.rawValue
        if status == .completed {
            params["completed_on"] = DateFormatter.makespaceYearMonthDay().string(from: Date())
        }
        request(path: MakespacePath.jobs.rawValue,
                method: .get,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getJobWithXid(_ jobXid: String,
                              success successBlock: @escaping SuccessResponseBlock,
                              error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.jobs.rawValue)/\(jobXid)"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func updateJob(withXid jobXid: String,
                          status: JobStatusType,
                          additionalValues: [String: Any],
                          success successBlock: @escaping SuccessResponseBlock,
                          error errorBlock: @escaping ErrorResponseBlock) {
        
        var params = additionalValues
        params["status"] = status.rawValue
        let path: String = "\(MakespacePath.jobs.rawValue)/\(jobXid)"
        request(path: path,
                method: .patch,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getDeliverySummaries(withFacilityXid facilityXid: String,
                                     numberOfDays: Int,
                                     success successBlock: @escaping SuccessResponseBlock,
                                     error errorBlock: @escaping ErrorResponseBlock) {
        let params: [String: Any] = ["days": (numberOfDays)]
        let path: String = "\(MakespacePath.places.rawValue)/\(facilityXid)/delivery-summaries"
        request(path: path,
                method: .get,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getDeliverySections(withFacilityXid facilityXid: String,
                                    date: Date,
                                    equipmentSlug slug: String,
                                    success successBlock: @escaping SuccessResponseBlock,
                                    error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        params["date"] = DateFormatter.makespaceYearMonthDay().string(from: date)
        params["equipment"] = slug

        let path: String = "\(MakespacePath.places.rawValue)/\(facilityXid)/delivery-places"
        request(path: path,
                method: .get,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getDeliveryItems(withJobXid jobXid: String,
                                 success successBlock: @escaping SuccessResponseBlock,
                                 error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.jobs.rawValue)/\(jobXid)/delivery-items"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func createDeliveryJob(with date: Date,
                                  facilityXid: String,
                                  placeXids: [Any],
                                  equipmentSlug slug: String,
                                  success successBlock: @escaping SuccessResponseBlock,
                                  error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        params["delivery_places"] = placeXids
        params["equipment"] = [slug]
        params["from_place"] = facilityXid
        params["type"] = "DELIVERY"
        params["status"] = "STARTED"
        
        let dateString: String = DateFormatter.makespaceYearMonthDay().string(from: date)
        params["scheduled_date"] = dateString
        request(path: MakespacePath.jobs.rawValue,
                method: .post,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func createTransitJob(with date: Date,
                                 fromPlaceXid: String,
                                 toPlaceXid: String,
                                 description: String,
                                 success successBlock: @escaping SuccessResponseBlock,
                                 error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        params["type"] = "TRANSIT"
        params["status"] = "STARTED"
        params["from_place"] = fromPlaceXid
        params["to_place"] = toPlaceXid
        params["description"] = description

        let dateString: String = DateFormatter.makespaceYearMonthDay().string(from: date)
        params["scheduled_date"] = dateString
        request(path: MakespacePath.jobs.rawValue,
                method: .post,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getTransitItems(withJobXid jobXid: String,
                                success successBlock: @escaping SuccessResponseBlock,
                                error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.jobs.rawValue)/\(jobXid)/transit-items"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func addPalletToJob(withXid jobXid: String,
                               palletXid: String,
                               scanTime: Date,
                               success successBlock: @escaping SuccessResponseBlock,
                               error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.jobs.rawValue)/\(jobXid)/transit-items"
        var params = [String: Any]()
        params["place"] = palletXid

        let dateString: String = DateFormatter.makespace().string(from: scanTime)
        params["scanned_on"] = dateString
        request(path: path,
                method: .post,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func removePalletFromJob(withXid jobXid: String,
                                    palletXid: String,
                                    success successBlock: @escaping SuccessResponseBlock,
                                    error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.jobs.rawValue)/\(jobXid)/transit-items/\(palletXid)"
        request(path: path,
                method: .delete,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }

    // MARK: - Container Info
    
    public func updateContainer(withLocator containerLocator: String,
                                length: Double,
                                width: Double,
                                height: Double,
                                standardSizeName: String,
                                handlingClass: String,
                                success successBlock: @escaping SuccessResponseBlock,
                                error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        params["length"] = length
        params["width"] = width
        params["height"] = height
        if handlingClass != "" {
            params["handling_class"] = handlingClass
        }
        if standardSizeName != "" {
            params["standard_size"] = standardSizeName
        }
        let path: String = "\(MakespacePath.containers.rawValue)/\(containerLocator)"
        request(path: path,
                method: .patch,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func updateContainer(withLocator containerLocator: String,
                                standardSizeName: String,
                                handlingClass: String,
                                success successBlock: @escaping SuccessResponseBlock,
                                error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if handlingClass != "" {
            params["handling_class"] = handlingClass
        }
        params["standard_size"] = standardSizeName
        let path: String = "\(MakespacePath.containers.rawValue)/\(containerLocator)"
        request(path: path,
                method: .patch,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getContainerWithLocator(_ containerLocator: String,
                                        success successBlock: @escaping SuccessResponseBlock,
                                        error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.containers.rawValue)/\(containerLocator)"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getStandardSizes(success successBlock: @escaping SuccessResponseBlock,
                                 error errorBlock: @escaping ErrorResponseBlock) {
        request(path: "standard-sizes",
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    // MARK: - Timed Containers
    
    public func getTimedContainers(withPlaceXid placeXid: String,
                                   success successBlock: @escaping SuccessResponseBlock,
                                   error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.places.rawValue)/\(placeXid)/containers"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func seeTimedContainers(_ timedContainers: [[String: Any]],
                                   withPlaceXid xid: String,
                                   success successBlock: @escaping SuccessResponseBlock,
                                   error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if !timedContainers.isEmpty {
            params = ["scans": timedContainers]
        }
        let path: String = "\(MakespacePath.places.rawValue)/\(xid)/scan"
        request(path: path,
                method: .post,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func unseeTimedContainers(_ timedContainers: [[String: Any]],
                                     withPlaceXid xid: String,
                                     success successBlock: @escaping SuccessResponseBlock,
                                     error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if !timedContainers.isEmpty {
            params = ["scans": timedContainers]
        }
        let path: String = "\(MakespacePath.places.rawValue)/\(xid)/scan?remove=true"
        request(path: path,
                method: .post,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    // MARK: - Images
    public func createFile(withSuccess successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        let params: [String: Any] = ["mime_type": "image/jpeg", "description": "Uploaded Image"]
        
        request(path: MakespacePath.files.rawValue,
                method: .post,
                with: params,
                paginated: false,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getS3UploadParametersForFile(withXid xid: String,
                                      success successBlock: @escaping SuccessResponseBlock,
                                      error errorBlock: @escaping ErrorResponseBlock) {
        let path = "\(MakespacePath.files.rawValue)/\(xid)/s3-upload-params"
        request(path: path,
                method: .post,
                with: [String:Any](),
                paginated: false,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func addImageToRemoteCache(withURL imageUrl: String,
                               locator: String,
                               success successBlock: @escaping SuccessResponseBlock,
                               error errorBlock: @escaping ErrorResponseBlock) {
        let path = "\(MakespacePath.containers.rawValue)/\(locator)/image-cache"
        var params = [String: Any]()
        params["image"] = imageUrl
        params["container"] = locator

        request(path: path,
                method: .post,
                with: params,
                paginated: false,
                success: successBlock,
                failure: errorBlock)
    }
    
    // MARK: - Tasks
    
    public func getTasksWithSuccessBlock(_ successBlock: @escaping SuccessResponseBlock,
                                         error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.tasks.rawValue)/me"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getTaskWithXid(_ xid: String,
                               success successBlock: @escaping SuccessResponseBlock,
                               error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.tasks.rawValue)/\(xid)"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func updateTask(withTaskXid xid: String,
                           taskStatus: String,
                           success successBlock: @escaping SuccessResponseBlock,
                           error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.tasks.rawValue)/\(xid)"
        let params: [String: Any] = ["status": taskStatus]
        request(path: path,
                method: .patch,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func addNotes(with note: String,
                         forTaskXid taskXid: String,
                         success successBlock: @escaping SuccessResponseBlock,
                         error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.tasks.rawValue)/\(taskXid)"
        let params: [String: Any] = ["booking": ["admin_notes": [["content": note]]]]
        request(path: path,
                method: .patch,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getTaskEvents(withTaskXid xid: String,
                              success successBlock: @escaping SuccessResponseBlock,
                              error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.tasks.rawValue)/\(xid)/events"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func createEvent(withParams requestParams: [[String:Any]],
                            success successBlock: @escaping SuccessResponseBlock,
                            error errorBlock: @escaping ErrorResponseBlock) {
        request(path: MakespacePath.events.rawValue,
                method: .post,
                with: requestParams.asParameters(),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func deleteEvent(withXid xid: String,
                            success successBlock: @escaping SuccessResponseBlock,
                            error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.events.rawValue)/\(xid)"
        request(path: path,
                method: .delete,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func submitSignature(with image: UIImage,
                                withFullName fullName: String?,
                                withRefId refId: String,
                                withPerformedOn performedOn: Date,
                                withEventXidArray eventXids: [String],
                                success successBlock: @escaping SuccessResponseBlock,
                                error errorBlock: @escaping ErrorResponseBlock) {
        var eventsXids = [[String:String]]()
        for xid: String in eventXids {
            eventsXids.append(["xid": xid])
        }
        var params: [String: Any] = ["_reference": refId,
                                     
                                     "events": eventsXids,
                                     
                                     "image": image.base64DataUri(),
                                     
                                     "performed_on": DateFormatter.makespace().string(from: Date())]
        // only add full name if it is set
        if fullName != nil {
            params["full_name"] = fullName
        }
        request(path: MakespacePath.signatures.rawValue,
                method: .post,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    // MARK: - Bookings
    
    public func getBookingsWithUserXid(_ userXid: String,
                                       success successBlock: @escaping SuccessResponseBlock,
                                       error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.accounts.rawValue)/\(userXid)/bookings"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    // MARK: - Staff
    
    public func getStaffInfo(success successBlock: @escaping SuccessResponseBlock,
                             error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.staff.rawValue)/me"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getStaffInfo(forAccessToken token:String,
                             success successBlock: @escaping SuccessResponseBlock,
                             error errorBlock: @escaping ErrorResponseBlock) {
        //set a specific token on the api call
        let path: String = "\(MakespacePath.staff.rawValue)/me"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                headers: ["Authorization" : "Bearer " + token],
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getMyStaffInfo(success successBlock: @escaping SuccessResponseBlock,
                               error errorBlock: @escaping ErrorResponseBlock) {
        self.getMyStaffInfoExpanded(false, success: successBlock, error: errorBlock)
    }
    
    public func getMyStaffInfoExpanded(_ expanded: Bool,
                                       success successBlock: @escaping SuccessResponseBlock,
                                       error errorBlock: @escaping ErrorResponseBlock) {
        var path: String
        if expanded {
            path = "\(MakespacePath.staff.rawValue)/me?expand=profile"
        }
        else {
            path = "\(MakespacePath.staff.rawValue)/me"
        }
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func updateMyStaffLocation(withLatitude lat: Double,
                                      longitude lon: Double,
                                      success successBlock: @escaping SuccessResponseBlock,
                                      error errorBlock: @escaping ErrorResponseBlock) {
        self.updateMyStaffLocation(withLatitude: lat,
                                   longitude: lon,
                                   eta: nil,
                                   booking: nil,
                                   success: successBlock,
                                   error: errorBlock)
    }
    
    public func updateMyStaffLocation(withLatitude lat: Double,
                                      longitude lon: Double,
                                      eta: Date?,
                                      booking currentBooking: String?,
                                      success successBlock: @escaping SuccessResponseBlock,
                                      error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.staff.rawValue)/me"
        var params: [String: Any] = ["lat": lat,
                                     "lon": lon]
        if let eta = eta {
            let etaString: String = DateFormatter.makespace().string(from: eta)
            params["expected_on"] = etaString
        }
        if let currentBooking = currentBooking,
            !currentBooking.isEmpty {
            params["booking"] = currentBooking
        }
        request(path: path,
                method: .patch,
                with: ["location" : params],
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getCustomerInfo(withXid userXid: String,
                                success successBlock: @escaping SuccessResponseBlock,
                                error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.accounts.rawValue)/\(userXid)"
        let params: [String: Any] = ["expand": "container_cycles"]
        request(path: path,
                method: .get,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func searchCustomers(withText searchText: String,
                                success successBlock: @escaping SuccessResponseBlock,
                                error errorBlock: @escaping ErrorResponseBlock) {
        let params: [String: Any] = ["q": searchText]
        let path: String = "search/accounts"
        request(path: path,
                method: .get,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    // MARK: - Places V3
    
    public func scanContainerAtPlace(withXid placeXid: String,
                                     withScanDataArray scanData: [Any],
                                     success successBlock: @escaping SuccessResponseBlock,
                                     error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.places.rawValue)/\(placeXid)/scan"
        let params: [String: Any] = ["scans": scanData]
        request(path: path,
                method: .post,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func setPlaceMarkerWithPlaceXid(_ placeXid: String,
                                           markerLocator: String,
                                           success successBlock: @escaping SuccessResponseBlock,
                                           error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.places.rawValue)/\(placeXid)"
        let params: [String: Any] = ["marker": markerLocator]
        request(path: path,
                method: .patch,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func setPlaceParentWithPlaceXid(_ subplaceXid: String,
                                           parentXid: String,
                                           success successBlock: @escaping SuccessResponseBlock,
                                           error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.places.rawValue)/\(subplaceXid)"
        let params: [String: Any] = ["parent": parentXid]
        request(path: path,
                method: .patch,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }

    // MARK: - Pickup Fees
    
    public func getPickupFeesForCustomer(withXid customerXid: String,
                                         bookingXid: String,
                                         success successBlock: @escaping SuccessResponseBlock,
                                         error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.accounts.rawValue)/\(customerXid)/bookings/\(bookingXid)/pickup-fees"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func getProductPrices(withFulfillerXid fulfillerXid: String,
                                 success successBlock: @escaping SuccessResponseBlock,
                                 error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.fulfillers.rawValue)/\(fulfillerXid)/prices"
        request(path: path,
                method: .get,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func setPickupFeesWithFees(_ pickupFees: [String],
                                      customerXid: String,
                                      bookingXid: String,
                                      success successBlock: @escaping SuccessResponseBlock,
                                      error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "\(MakespacePath.accounts.rawValue)/\(customerXid)/bookings/\(bookingXid)/pickup-fees"
        request(path: path,
                method: .put,
                with: [String: Any](),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    // MARK: - Questionnaire
    
    public func getQuestionsWithBookingXid(_ bookingXid: String,
                                           count: Int,
                                           success successBlock: @escaping SuccessResponseBlock,
                                           error errorBlock: @escaping ErrorResponseBlock) {
        let path: String = "bookings/\(bookingXid)/questions"
        let params: [String: Any] = ["count": (count)]
        request(path: path,
                method: .get,
                with: params,
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
    
    public func submitQuestionAnswers(withParams params: [[String: Any]],
                                      success successBlock: @escaping SuccessResponseBlock,
                                      error errorBlock: @escaping ErrorResponseBlock) {
        request(path: MakespacePath.questions.rawValue,
                method: .post,
                with: params.asParameters(),
                paginated: true,
                success: successBlock,
                failure: errorBlock)
    }
}
