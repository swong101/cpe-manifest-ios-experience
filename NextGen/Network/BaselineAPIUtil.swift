//
//  BaselineAPIUtil.swift
//

import Foundation
import NextGenDataManager

public enum BaselineAPIStudio: String {
    case wb = "WB"
    case nbcu = "NBCU"
}

public class BaselineAPIUtil: NextGenDataManager.APIUtil, TalentAPIUtil {
    
    public static var APIDomain = "https://vic57ayytg.execute-api.us-west-2.amazonaws.com/prod"
    public static var APINamespace = "baselineapi.com"
    
    private struct Endpoints {
        static let GetCredits = "/film/credits"
        static let GetTalentImages = "/talent/images"
        static let GetTalentDetails = "/talent"
    }
    
    private struct Keys {
        static let ParticipantID = "PARTICIPANT_ID"
        static let FullName = "FULL_NAME"
        static let Credit = "CREDIT"
        static let CreditGroup = "CREDIT_GROUP"
        static let Role = "ROLE"
        static let Filmography = "FILMOGRAPHY"
        static let SocialAccounts = "SOCIAL_ACCOUNTS"
        static let Posters = "POSTERS"
        static let ShortBio = "SHORT_BIO"
        static let MediumURL = "MEDIUM_URL"
        static let LargeURL = "LARGE_URL"
        static let FullURL = "FULL_URL"
        static let ProjectID = "PROJECT_ID"
        static let ProjectName = "PROJECT_NAME"
        static let Handle = "HANDLE"
        static let URL = "URL"
    }
    
    struct Headers {
        static let APIKey = "x-api-key"
        static let Studio = "X-Studio"
    }
    
    private struct Constants {
        static let MaxCredits = 15
        static let MaxFilmography = 10
    }
    
    public var featureAPIID: String?
    
    public convenience init(apiKey: String, featureAPIID: String? = nil, studio: BaselineAPIStudio = .wb) {
        self.init(apiDomain: BaselineAPIUtil.APIDomain)
        
        self.featureAPIID = featureAPIID
        self.customHeaders[Headers.APIKey] = apiKey
        self.customHeaders[Headers.Studio] = studio.rawValue
    }
    
    public func prefetchCredits(_ completion: @escaping (_ people: [Person]?) -> Void) {
        if let apiID = featureAPIID {
            _ = getJSONWithPath(Endpoints.GetCredits, parameters: ["id": apiID], successBlock: { (result) -> Void in
                if let results = result["result"] as? NSArray {
                    var people = [Person]()
                    
                    var i = 0
                    for talentInfo in results.subarray(with: NSRange(location: 0, length: min(Constants.MaxCredits, results.count))) {
                        if let talentInfo = talentInfo as? NSDictionary, let talentID = talentInfo[Keys.ParticipantID] as? NSNumber, let name = (talentInfo[Keys.FullName] as? String) {
                            let jobFunction = PersonJobFunction.build(rawValue: (talentInfo[Keys.Credit] as? String))
                            let character = talentInfo[Keys.Credit] as? String
                            people.append(Person(apiID: talentID.stringValue, name: name, jobFunction: jobFunction, billingBlockOrder: i, character: character))
                        }
                        
                        i += 1
                    }
                    
                    completion(people)
                }
            }) { (error) in
                print("Error fetching credits for ID \(apiID): \(error)")
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    
    public func getTalentImages(_ talentID: String, completion: @escaping (_ talentImages: [TalentImage]?) -> Void) {
        _ = getJSONWithPath(Endpoints.GetTalentImages, parameters: ["id": talentID], successBlock: { (result) -> Void in
            if let results = result["result"] as? NSArray, results.count > 0 {
                var talentImages = [TalentImage]()
                for talentImageInfo in results {
                    if let talentImageInfo = talentImageInfo as? NSDictionary {
                        var talentImage = TalentImage()
                        
                        if let thumbnailURLString = talentImageInfo[Keys.MediumURL] as? String {
                            talentImage.thumbnailImageURL = URL(string: thumbnailURLString)
                        }
                        
                        if let imageURLString = talentImageInfo[Keys.FullURL] as? String {
                            talentImage.imageURL = URL(string: imageURLString)
                        }
                        
                        talentImages.append(talentImage)
                    }
                }
                
                completion(talentImages)
            } else {
                completion(nil)
            }
        }) { (error) in
            print("Error fetching talent images for ID \(talentID): \(error)")
            completion(nil)
        }
    }
    
    public func getTalentDetails(_ talentID: String, completion: @escaping (_ biography: String?, _ socialAccounts: [SocialAccount]?, _ films: [Film]) -> Void) {
        _ = getJSONWithPath(Endpoints.GetTalentDetails, parameters: ["id": talentID], successBlock: { (result) in
            var socialAccounts = [SocialAccount]()
            if let socialAccountInfoList = result[Keys.SocialAccounts] as? NSArray {
                for socialAccountInfo in socialAccountInfoList {
                    if let socialAccountInfo = socialAccountInfo as? NSDictionary {
                        let handle = socialAccountInfo[Keys.Handle] as! String
                        let urlString = socialAccountInfo[Keys.URL] as! String
                        socialAccounts.append(SocialAccount(handle: handle, urlString: urlString))
                    }
                }
            }
            
            var films = [Film]()
            if let filmInfoList = result[Keys.Filmography] as? NSArray {
                for filmInfo in filmInfoList {
                    if let filmInfo = filmInfo as? NSDictionary {
                        let id = (filmInfo[Keys.ProjectID] as! NSNumber).stringValue
                        let title = filmInfo[Keys.ProjectName] as! String
                        
                        var imageURL: URL?
                        if let posterImageURLString = ((filmInfo[Keys.Posters] as? NSArray)?.firstObject as? NSDictionary)?[Keys.LargeURL] as? String {
                            imageURL = URL(string: posterImageURLString)
                        }
                        
                        films.append(Film(id: id, title: title, imageURL: imageURL))
                    }
                }
            }
            
            completion(result[Keys.ShortBio] as? String, socialAccounts, films)
        }) { (error) in
            print("Error fetching talent details for ID \(talentID): \(error)")
            completion(nil, nil, [])
        }
    }
    
}
