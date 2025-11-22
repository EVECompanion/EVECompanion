//
//  ECKAPIScope.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.05.24.
//

import Foundation

internal enum ECKAPIScope: String, CaseIterable {
    
    case publicData = "publicData"
    case respondCalendarEvents = "esi-calendar.respond_calendar_events.v1"
    case readCalendarEvents = "esi-calendar.read_calendar_events.v1"
    case readLocation = "esi-location.read_location.v1"
    case readShipType = "esi-location.read_ship_type.v1"
    case organizeMail = "esi-mail.organize_mail.v1"
    case readMail = "esi-mail.read_mail.v1"
    case sendMail = "esi-mail.send_mail.v1"
    case readSkills = "esi-skills.read_skills.v1"
    case readSkillQueue = "esi-skills.read_skillqueue.v1"
    case readCharacterWallet = "esi-wallet.read_character_wallet.v1"
    case searchStructures = "esi-search.search_structures.v1"
    case readClones = "esi-clones.read_clones.v1"
    case readContacts = "esi-characters.read_contacts.v1"
    case readStructures = "esi-universe.read_structures.v1"
    case readKillmails = "esi-killmails.read_killmails.v1"
    case readAssets = "esi-assets.read_assets.v1"
    case managePlanets = "esi-planets.manage_planets.v1"
    case readFleet = "esi-fleets.read_fleet.v1"
    case writeFleet = "esi-fleets.write_fleet.v1"
    case openWindow = "esi-ui.open_window.v1"
    case writeWaypoint = "esi-ui.write_waypoint.v1"
    case writeContacts = "esi-characters.write_contacts.v1"
    case readFittings = "esi-fittings.read_fittings.v1"
    case writeFittings = "esi-fittings.write_fittings.v1"
    case structureMarkets = "esi-markets.structure_markets.v1"
    case readLoyalty = "esi-characters.read_loyalty.v1"
    case readChatChannels = "esi-characters.read_chat_channels.v1"
    case readMedals = "esi-characters.read_medals.v1"
    case readStandings = "esi-characters.read_standings.v1"
    case readAgentsResearch = "esi-characters.read_agents_research.v1"
    case readCharacterJobs = "esi-industry.read_character_jobs.v1"
    case readCharacterOrders = "esi-markets.read_character_orders.v1"
    case readCharacterBlueprints = "esi-characters.read_blueprints.v1"
    case readOnline = "esi-location.read_online.v1"
    case readCharacterContracts = "esi-contracts.read_character_contracts.v1"
    case readImplants = "esi-clones.read_implants.v1"
    case readFatigue = "esi-characters.read_fatigue.v1"
    case readNotifications = "esi-characters.read_notifications.v1"
    case readCharacterMining = "esi-industry.read_character_mining.v1"
    case readTitles = "esi-characters.read_titles.v1"
    case readFWStats = "esi-characters.read_fw_stats.v1"
    
    case corpReadStructures = "esi-corporations.read_structures.v1"
    case characterReadCorpRoles = "esi-characters.read_corporation_roles.v1"
    case corpReadKillmails = "esi-killmails.read_corporation_killmails.v1"
    case corpTrackMembers = "esi-corporations.track_members.v1"
    case corpReadWallets = "esi-wallet.read_corporation_wallets.v1"
    case corpReadDivisions = "esi-corporations.read_divisions.v1"
    case corpReadContacts = "esi-corporations.read_contacts.v1"
    case corpReadAssets = "esi-assets.read_corporation_assets.v1"
    case corpReadTitles = "esi-corporations.read_titles.v1"
    case corpReadBlueprints = "esi-corporations.read_blueprints.v1"
    case corpReadContracts = "esi-contracts.read_corporation_contracts.v1"
    case corpReadStandings = "esi-corporations.read_standings.v1"
    case corpReadStarbases = "esi-corporations.read_starbases.v1"
    case corpReadJobs = "esi-industry.read_corporation_jobs.v1"
    case corpReadOrders = "esi-markets.read_corporation_orders.v1"
    case corpReadContainerLogs = "esi-corporations.read_container_logs.v1"
    case corpReadMining = "esi-industry.read_corporation_mining.v1"
    case corpReadFacilities = "esi-corporations.read_facilities.v1"
    case corpReadMedals = "esi-corporations.read_medals.v1"
    case alliancesReadContacts = "esi-alliances.read_contacts.v1"
    case corpReadFWStats = "esi-corporations.read_fw_stats.v1"
    case corpReadProjects = "esi-corporations.read_projects.v1"
    case corpReadCustomsOffices = "esi-planets.read_customs_offices.v1"
    
    static var characterScopes: [ECKAPIScope] {
        return [
            .publicData,
            .respondCalendarEvents,
            .readCalendarEvents,
            .readLocation,
            .readShipType,
            .organizeMail,
            .readMail,
            .sendMail,
            .readSkills,
            .readSkillQueue,
            .readCharacterWallet,
            .searchStructures,
            .readClones,
            .readContacts,
            .readStructures,
            .readKillmails,
            .readAssets,
            .managePlanets,
            .readFleet,
            .writeFleet,
            .openWindow,
            .writeWaypoint,
            .writeContacts,
            .readFittings,
            .writeFittings,
            .structureMarkets,
            .readLoyalty,
            .readChatChannels,
            .readMedals,
            .readStandings,
            .readAgentsResearch,
            .readCharacterJobs,
            .readCharacterOrders,
            .readCharacterBlueprints,
            .readOnline,
            .readCharacterContracts,
            .readImplants,
            .readFatigue,
            .readNotifications,
            .readCharacterMining,
            .readTitles,
            .readFWStats,
            .corpReadProjects
        ]
    }
    
    static var corpScopes: [ECKAPIScope] {
        return [
            .corpReadStructures,
            .characterReadCorpRoles,
            .corpReadKillmails,
            .corpTrackMembers,
            .corpReadWallets,
            .corpReadDivisions,
            .corpReadContacts,
            .corpReadAssets,
            .corpReadTitles,
            .corpReadBlueprints,
            .corpReadContracts,
            .corpReadStandings,
            .corpReadStarbases,
            .corpReadJobs,
            .corpReadOrders,
            .corpReadContainerLogs,
            .corpReadMining,
            .corpReadFacilities,
            .corpReadMedals,
            .alliancesReadContacts,
            .corpReadFWStats,
            .corpReadProjects,
            .corpReadCustomsOffices
        ]
    }
    
}

extension Array where Element == ECKAPIScope {
    
    var scopesString: String {
        return self.map({ $0.rawValue }).joined(separator: " ")
    }
    
}
