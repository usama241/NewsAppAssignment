import Foundation

enum APIRouter {

    case newsList(source: String, apiKey: String)

     var method: HTTPMethod {
          return .get
     }
     
     //Endpoint for each API call
     var path: String {
          switch self {
         
          case .newsList:
              return "/top-headlines"
              
          }
     }
    
     // Headers for each API call
    var headers: [String: String] {
        return [
            "Accept": "application/json"
        ]
    }
     
    // Parameters for each API call
    var parameters: [String: Any] {
          switch self {
          case .newsList(let source, let apiKey):
              return [
                  "sources": source,
                  "apiKey": apiKey
              ]
          }
      }
     
     var baseURL: String {
          switch self {
          default:
               return Constants.apiBaseURL
          }
     }
}


