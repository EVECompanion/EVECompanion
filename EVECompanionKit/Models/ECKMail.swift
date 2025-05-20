//
//  ECKMail.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

public import Combine

public class ECKMail: ObservableObject, Identifiable, Decodable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case from
        case isRead = "is_read"
        case labels
        case mailId = "mail_id"
        case recipients
        case subject
        case timestamp
    }
    
    public var id: String {
        return mailId?.description ?? UUID().uuidString
    }
    
    public let from: Int?
    @Published public var isRead: Bool
    public let labels: [Int]?
    public let mailId: Int?
    public let recipients: [ECKMailRecipient]
    public let subject: String?
    public let timestamp: Date?
    let token: ECKToken
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var body: AttributedString?
    
    public var replyRecipient: [ECKMailRecipient] {
        var recipients = [ECKMailRecipient]()
        
        if let from = from {
            recipients = [.init(recipientId: from,
                                recipientType: .character)]
        }
        
        return recipients
    }
    
    public static let dummyRead: ECKMail = .init(from: 2123087197,
                                                 isRead: true,
                                                 labels: nil,
                                                 mailId: 0,
                                                 recipients: [.dummy],
                                                 subject: "Hey, this is a mail",
                                                 timestamp: .now - .fromDays(days: 1),
                                                 body: "This is the content of a mail with a really long body. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.")
    
    public static let dummyUnread: ECKMail = .init(from: 2123087197,
                                                   isRead: false,
                                                   labels: nil,
                                                   mailId: 1,
                                                   recipients: [.dummy],
                                                   subject: "A mail you have not read",
                                                   timestamp: .now - .fromHours(hours: 2),
                                                   body: "This is the content of a mail you have not read.")
    
    public static let dummyUnreadLong: ECKMail = .init(from: 2123087197,
                                                       isRead: false,
                                                       labels: nil,
                                                       mailId: 1,
                                                       recipients: [.dummy],
                                                       subject: "A mail you have not read with an incredibly long subject.",
                                                       timestamp: .now - .fromHours(hours: 2),
                                                       body: "This is another content of a mail you have not read.")
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.from = try container.decodeIfPresent(Int.self, forKey: .from)
        self.isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        self.labels = try container.decodeIfPresent([Int].self, forKey: .labels)
        self.mailId = try container.decodeIfPresent(Int.self, forKey: .mailId)
        self.recipients = try container.decode([ECKMailRecipient].self, forKey: .recipients)
        self.subject = try container.decodeIfPresent(String.self, forKey: .subject)
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        // swiftlint:disable:next force_cast
        self.token = decoder.userInfo[ECKWebService.tokenCodingUserInfoKey] as! ECKToken
    }
    
    private init(from: Int?,
                 isRead: Bool,
                 labels: [Int]?,
                 mailId: Int?,
                 recipients: [ECKMailRecipient],
                 subject: String?,
                 timestamp: Date?,
                 body: String?) {
        self.from = from
        self.isRead = isRead
        self.labels = labels
        self.mailId = mailId
        self.recipients = recipients
        self.subject = subject
        self.timestamp = timestamp
        self.body = "This is a nice mail."
        self.token = .dummy
        self.body = body?.convertToAttributed()
        self.loadingState = .ready
    }
    
    @MainActor
    public func fetchBody() async {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            return
        }
        
        guard let mailId else {
            self.body = ""
            self.loadingState = .ready
            return
        }
        
        self.loadingState = .loading
        
        let resource = ECKFetchMailBodyResource(token: token, mailId: mailId)
        do {
            let response = try await ECKWebService().loadResource(resource: resource).response
            self.body = (response.body ?? "")?.convertToAttributed()
            self.loadingState = .ready
        } catch {
            self.loadingState = .error
        }
    }
    
    public static func == (lhs: ECKMail, rhs: ECKMail) -> Bool {
        return lhs.from == rhs.from &&
               lhs.isRead == rhs.isRead &&
               lhs.labels == rhs.labels &&
               lhs.mailId == rhs.mailId &&
               lhs.recipients == rhs.recipients &&
               lhs.subject == rhs.subject &&
               lhs.timestamp == rhs.timestamp &&
               lhs.token == rhs.token &&
               lhs.body == rhs.body
    }
    
}
