//
//  OpsService.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/7/17.
//
//

import Foundation

let MS_PLACES_LOOKUP_PATH = "places"
let MS_CONTAINERS_LOOKUP_PATH = "containers"
let MS_CONTAINER_SETS_LOOKUP_PATH = "container-sets"
let MS_JOBS_LOOKUP_PATH = "jobs"
let MS_FILES_LOOKUP_PATH = "files"
let MS_TASKS_LOOKUP_PATH = "tasks"
let MS_EVENTS_LOOKUP_PATH = "events"
let MS_STAFF_LOOKUP_PATH = "staff"
let MS_ACCOUNTS_LOOKUP_PATH = "accounts"

public enum JobStatusType: Int
{
    case created = 10
    case started = 50
    case completed = 70
    case canceled = 90
    
    var stringKey:String {
        switch self {
        case .created:
            return "CREATED"
        case .started:
            return "STARTED"
        case .completed:
            return "COMPLETED"
        case .canceled:
            return "CANCELED"
        }
    }
}

open class OpsService: AbstractBaseService {
    
    // MARK: - Sets
    
    public func getContainerSet(withLocator locator: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        request(path: "container-sets/\(locator)", method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func updateContainerSet(withLocator locator: String, length: NSNumber, width: NSNumber, height: NSNumber, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
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
        request(path: "container-sets/\(locator)", method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Places
    
    public func getPlacesWithParameters(_ parameters: [String: Any], success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        request(path: MS_PLACES_LOOKUP_PATH, method: .get, with: parameters, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getPlacesWithLatitude(_ lat: Double, longitude lon: Double, parentXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        params["lat"] = lat
        params["lon"] = lon
        
        if parentXid != "" {
            params["parent"] = parentXid
        }
        try? self.getPlacesWithParameters(params, success: successBlock, error: errorBlock)
    }
    
    public func getPlacesWithLocator(_ locator: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if locator != "" {
            params["marker_locator"] = locator
        }
        request(path: MS_PLACES_LOOKUP_PATH, method: .get, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func updatePlace(withPlaceXid placeXid: String, locator updatedLocator: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params: [String: Any] = ["marker": updatedLocator]
        request(path: "\(MS_PLACES_LOOKUP_PATH)/\(placeXid)", method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Jobs
    
    public func getJobsWithFacilityXid(_ facilityXid: String, status: JobStatusType, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if (facilityXid is String) && (facilityXid.characters.count ?? 0) > 0 {
            params["facility"] = facilityXid
        }
        params["status"] = status.stringKey
        if status == .completed {
            params["completed_on"] = DateFormatter.makespaceYearMonthDay().string(from: Date())
        }
        request(path: "jobs", method: .get, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getJobWithXid(_ jobXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_JOBS_LOOKUP_PATH)/\(jobXid)"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func updateJob(withXid jobXid: String, status: JobStatusType, additionalValues: [String: Any], success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if (additionalValues is [String: Any]) {
            for (k, v) in additionalValues { params.updateValue(v, forKey: k) }
        }
        params["status"] = status.stringKey
        var path: String = "\(MS_JOBS_LOOKUP_PATH)/\(jobXid)"
        request(path: path, method: .patch, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getDeliverySummaries(withFacilityXid facilityXid: String, numberOfDays: Int, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params: [String: Any] = ["days": (numberOfDays)]
        var path: String = "\(MS_PLACES_LOOKUP_PATH)/\(facilityXid)/delivery-summaries"
        request(path: path, method: .get, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getDeliverySections(withFacilityXid facilityXid: String, date: Date, equipmentSlug slug: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if (date is Date) {
            params["date"] = DateFormatter.makespaceYearMonthDay().string(from: date)
        }
        if (slug is String) {
            params["equipment"] = slug
        }
        var path: String = "\(MS_PLACES_LOOKUP_PATH)/\(facilityXid)/delivery-places"
        request(path: path, method: .get, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getDeliveryItems(withJobXid jobXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_JOBS_LOOKUP_PATH)/\(jobXid)/delivery-items"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func createDeliveryJob(with date: Date, facilityXid: String, placeXids: [Any], equipmentSlug slug: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        params["delivery_places"] = placeXids
        if (slug is String) {
            params["equipment"] = [slug]
        }
        if (facilityXid is String) {
            params["from_place"] = facilityXid
        }
        params["type"] = "DELIVERY"
        params["status"] = "STARTED"
        var dateString: String = DateFormatter.makespaceYearMonthDay().string(from: date)
        params["scheduled_date"] = dateString
        request(path: MS_JOBS_LOOKUP_PATH, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func createTransitJob(with date: Date, fromPlaceXid: String, toPlaceXid: String, description: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        params["type"] = "TRANSIT"
        params["status"] = "STARTED"
        if (fromPlaceXid is String) {
            params["from_place"] = fromPlaceXid
        }
        if (toPlaceXid is String) {
            params["to_place"] = toPlaceXid
        }
        if (description is String) {
            params["description"] = description
        }
        var dateString: String = DateFormatter.makespaceYearMonthDay().string(from: date)
        params["scheduled_date"] = dateString
        request(path: MS_JOBS_LOOKUP_PATH, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getTransitItems(withJobXid jobXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_JOBS_LOOKUP_PATH)/\(jobXid)/transit-items"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func addPalletToJob(withXid jobXid: String, palletXid: String, scanTime: Date, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_JOBS_LOOKUP_PATH)/\(jobXid)/transit-items"
        var params = [String: Any]()
        if (palletXid is String) {
            params["place"] = palletXid
        }
        var dateString: String = DateFormatter.makespace().string(from: scanTime)
        params["scanned_on"] = dateString
        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func removePalletFromJob(withXid jobXid: String, palletXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_JOBS_LOOKUP_PATH)/\(jobXid)/transit-items/\(palletXid)"
        request(path: path, method: .delete, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Container Places
    
    public func deleteContainerPlace(withXid containerPlaceXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
    }
    // MARK: - Container Info
    
    public func updateContainer(withLocator containerLocator: String, length: NSNumber, width: NSNumber, height: NSNumber, standardSizeName: String, handlingClass: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
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
        var path: String = "\(MS_CONTAINERS_LOOKUP_PATH)/\(containerLocator)"
        request(path: path, method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func updateContainer(withLocator containerLocator: String, standardSizeName: String, handlingClass: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if handlingClass != "" {
            params["handling_class"] = handlingClass
        }
        params["standard_size"] = standardSizeName
        var path: String = "\(MS_CONTAINERS_LOOKUP_PATH)/\(containerLocator)"
        request(path: path, method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getContainerWithLocator(_ containerLocator: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_CONTAINERS_LOOKUP_PATH)/\(containerLocator)"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getStandardSizes(success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        request(path: "standard-sizes", method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Timed Containers
    
    public func getTimedContainers(withPlaceXid placeXid: String, requestKey key: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_PLACES_LOOKUP_PATH)/\(placeXid)/containers"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func seeTimedContainers(_ timedContainers: [Any], withPlaceXid xid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if !timedContainers.isEmpty {
            params = ["scans": timedContainers]
        }
        var path: String = "\(MS_PLACES_LOOKUP_PATH)/\(xid)/scan"
        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func unseeTimedContainers(_ timedContainers: [Any], withPlaceXid xid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params = [String: Any]()
        if !timedContainers.isEmpty {
            params = ["scans": timedContainers]
        }
        var path: String = "\(MS_PLACES_LOOKUP_PATH)/\(xid)/scan?remove=true"
        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func seeTimedContainers(_ timedContainers: [Any], withJobXid jobXid: String, placeXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "v2/ops/jobs/\(jobXid)/see_containers"
        var params: [String: Any] = ["place": placeXid, "container_times": timedContainers]
        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func unseeTimedContainers(_ timedContainers: [Any], withJobXid jobXid: String, placeXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "v2/ops/jobs/\(jobXid)/unsee_containers"
        var params: [String: Any] = ["place": placeXid, "container_times": timedContainers]

        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Images
    //- (NSURLSessionDataTask *)createFileWithSuccess:(@escaping SuccessResponseBlock)success
    //                                          error:(ErrorResponseBlock)errorBlock
    //{
    //
    //
    //    NSDictionary *params = @{@"mime_type" : @"image/jpeg", @"description" : @"Uploaded Image"};
    //
    //    NSURLSessionDataTask *task = [self POST:MS_FILES_LOOKUP_PATH parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
    //        success(responseObject);
    //    } failure:errorBlock];
    //
    //    return task;
    //}
    //
    //- (NSURLSessionDataTask *)getS3UploadParametersForFileWithXid:(NSString *)xid
    //                                                      success:(@escaping SuccessResponseBlock)success
    //                                                        error:(ErrorResponseBlock)errorBlock
    //{
    //
    //
    //    NSString *path = [NSString stringWithFormat:@"%@/%@/s3-upload-params", MS_FILES_LOOKUP_PATH, xid];
    //
    //    NSURLSessionDataTask *task = [self POST:path parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
    //        success(responseObject);
    //    } failure:errorBlock];
    //
    //    return task;
    //}
    //
    //- (NSURLSessionDataTask *)addImageToRemoteCacheWithURL:(NSString *)imageUrl
    //                                               locator:(NSString *)locator
    //                                               success:(@escaping SuccessResponseBlock)success
    //                                                 error:(ErrorResponseBlock)errorBlock
    //{
    //
    //
    //    NSString *path = [NSString stringWithFormat:@"%@/%@/image-cache", MS_CONTAINERS_LOOKUP_PATH, locator];
    //    NSMutableDictionary *params = [NSMutableDictionary new];
    //
    //    if ([imageUrl isKindOfClass:[NSString class]]) {
    //        params[@"image"] = imageUrl;
    //    }
    //
    //    if ([locator isKindOfClass:[NSString class]]) {
    //        params[@"container"] = locator;
    //    }
    //
    //    NSURLSessionDataTask *task = [self POST:path parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
    //        success(responseObject);
    //    } failure:errorBlock];
    //
    //    return task;
    //}
    //- (void)uploadImage:(NSData *)imageData
    //        withLocator:(NSString *)locator
    //            success:(@escaping SuccessResponseBlock)successBlock
    //              error:(ErrorResponseBlock)errorBlock
    //{
    //    self.requestSerializer = [self requestSerializerForType:MSWebServiceRequestTypeHTTP];
    //    NSString *path = [NSString stringWithFormat:@"v2/ops/containers/%@/images", locator];
    //
    //
    //    [self POST:path parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    //        [formData appendPartWithFileData:imageData name:@"file" fileName:@"capturedPhoto.jpg" mimeType:@"image/jpeg"];
    //    } success:^(NSURLSessionDataTask *task, id responseObject) {
    //
    //        [weakSelf handleSuccessResponse:responseObject
    //                                success:successBlock
    //                                  error:errorBlock];
    //    } failure:errorBlock];
    //}
    //
    //- (void)updateContainerWithLocator:(NSString *)locator
    //                             isBin:(NSNumber*)isBin
    //                              size:(NSNumber*)size
    //                           success:(@escaping SuccessResponseBlock)successBlock
    //                             error:(ErrorResponseBlock)errorBlock
    //{
    //    self.requestSerializer = [self requestSerializerForType:MSWebServiceRequestTypeHTTP];
    //    NSString *path = [NSString stringWithFormat:@"v2/ops/containers/%@", locator];
    //    NSDictionary *params = @{
    //                             @"is_bin":isBin,
    //                             @"size":size
    //                             };
    //
    //
    //    [self PATCH:path parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
    //
    //        [weakSelf handleSuccessResponse:responseObject
    //                                success:successBlock
    //                                  error:errorBlock];
    //    } failure:errorBlock];
    //}
    
    public func deleteItemImage(withXid itemImageXid: String, withItemXid itemXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "v2/ops/items/\(itemXid)/images/\(itemImageXid)"
        request(path: path, method: .delete, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Tasks
    
    public func getTasksWithSuccessBlock(_ successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_TASKS_LOOKUP_PATH)/me"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getTaskWithXid(_ xid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_TASKS_LOOKUP_PATH)/\(xid)"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func updateTask(withTaskXid xid: String, taskStatus: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_TASKS_LOOKUP_PATH)/\(xid)"
        var params: [String: Any] = ["status": taskStatus]
        request(path: path, method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func addNotes(with note: String, forTaskXid taskXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_TASKS_LOOKUP_PATH)/\(taskXid)"
        var params: [String: Any] = ["booking": ["admin_notes": [["content": note]]]]
        request(path: path, method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getTaskEvents(withTaskXid xid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_TASKS_LOOKUP_PATH)/\(xid)/events"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
//    public func createEvent(withParams requestParams: [Any], success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
//        request(path: MS_EVENTS_LOOKUP_PATH, method: .post, with: requestParams, paginated: true, success: successBlock, failure: errorBlock)
//    }
    
    public func deleteEvent(withXid xid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_EVENTS_LOOKUP_PATH)/\(xid)"
        request(path: path, method: .delete, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
//    public func submitSignature(with image: UIImage, withFullName fullName: String, withRefId refId: String, withPerformedOn performedOn: Date, withEventXidArray eventXids: [Any], success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
//        var path: String = "signatures"
//        var eventsXids = [Any]()
//        for xid: String in eventXids {
//            eventsXids.append(["xid": xid])
//        }
//        var params: [String: Any] = ["_reference": refId, "events": eventsXids, "image": image.base64DataUri(), "performed_on": DateFormatter.makespace().string(from: Date())]
//        // only add full name if it is set
//        if fullName && (fullName.characters.count ?? 0) > 0 {
//            params["full_name"] = fullName
//        }
//        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
//    }
    // MARK: - Bookings
    
    public func getBookingsWithUserXid(_ userXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_ACCOUNTS_LOOKUP_PATH)/\(userXid)/bookings"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Staff
    
    public func getStaffInfo(forAccessToken token: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_STAFF_LOOKUP_PATH)/me"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getMyStaffInfo(success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        try? self.getMyStaffInfoExpanded(false, success: successBlock, error: errorBlock)
    }
    
    public func getMyStaffInfoExpanded(_ expanded: Bool, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String
        if expanded {
            path = "\(MS_STAFF_LOOKUP_PATH)/me?expand=profile"
        }
        else {
            path = "\(MS_STAFF_LOOKUP_PATH)/me"
        }
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
//    public func updateMyStaffLocation(withLatitude lat: NSNumber, longitude lon: NSNumber, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
//        try? self.updateMyStaffLocation(withLatitude: lat, longitude: lon, eta: nil, booking: nil, success: successBlock)
//    }
//    
//    public func updateMyStaffLocation(withLatitude lat: NSNumber, longitude lon: NSNumber, eta: Date?, booking currentBooking: String?, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
//        var path: String = "\(MS_STAFF_LOOKUP_PATH)/me"
//        var params: [String: Any] = ["location": ["lat": lat, "lon": lon]]
//        if let eta = eta {
//            var etaString: String = DateFormatter.makespace().string(from: eta)
//            params["location"]["expected_on"] = etaString
//        }
//        if let currentBooking = currentBooking, !currentBooking.isEmpty {
//            params["location"]["booking"] = currentBooking
//        }
//        request(path: path, method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
//    }
    
    public func getCustomerInfo(withXid userXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_ACCOUNTS_LOOKUP_PATH)/\(userXid)"
        var params: [String: Any] = ["expand": "container_cycles"]
        request(path: path, method: .get, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func searchCustomers(withText searchText: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params: [String: Any] = ["q": searchText]
        var path: String = "search/accounts"
        request(path: path, method: .get, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Places V3
    
    public func scanContainerAtPlace(withXid placeXid: String, withScanDataArray scanData: [Any], success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_PLACES_LOOKUP_PATH)/\(placeXid)/scan"
        var params: [String: Any] = ["scans": scanData]
        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getPlaceWithMarkerLocator(_ locator: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var params: [String: Any] = ["marker_locator": locator]
        request(path: MS_PLACES_LOOKUP_PATH, method: .get, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func setPlaceMarkerWithPlaceXid(_ placeXid: String, markerLocator: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_PLACES_LOOKUP_PATH)/\(placeXid)"
        var params: [String: Any] = ["marker": markerLocator]
        request(path: path, method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func setPlaceParentWithPlaceXid(_ subplaceXid: String, parentXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_PLACES_LOOKUP_PATH)/\(subplaceXid)"
        var params: [String: Any] = ["parent": parentXid]
        request(path: path, method: .patch, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - debug call
    
    public func submitDebugData(_ data: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "/api/v2/ops/log/debug"
        var params: [String: Any] = ["log_data": data]
        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Pickup Fees
    
    public func getPickupFeesForCustomer(withXid customerXid: String, bookingXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_ACCOUNTS_LOOKUP_PATH)/\(customerXid)/bookings/\(bookingXid)/pickup-fees"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func getProductPrices(withFulfillerXid fulfillerXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "fulfillers/\(fulfillerXid)/prices"
        request(path: path, method: .get, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    
    public func setPickupFeesWithFees(_ pickupFees: [String], customerXid: String, bookingXid: String, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "\(MS_ACCOUNTS_LOOKUP_PATH)/\(customerXid)/bookings/\(bookingXid)/pickup-fees"
        request(path: path, method: .put, with: [String: Any](), paginated: true, success: successBlock, failure: errorBlock)
    }
    // MARK: - Questionnaire
    
    public func getQuestionsWithBookingXid(_ bookingXid: String, count: Int, success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
        var path: String = "bookings/\(bookingXid)/questions"
        var params: [String: Any] = ["count": (count)]
        request(path: path, method: .get, with: params, paginated: true, success: successBlock, failure: errorBlock)
    }
    
//    public func submitQuestionAnswers(withParams params: [[String: Any]], success successBlock: @escaping SuccessResponseBlock, error errorBlock: @escaping ErrorResponseBlock) {
//        var path: String = "question_answers"
//        request(path: path, method: .post, with: params, paginated: true, success: successBlock, failure: errorBlock)
//    }
}
