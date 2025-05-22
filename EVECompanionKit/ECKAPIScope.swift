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
    
    static var allScopesString: String {
        return Self.allCases.map({ $0.rawValue }).joined(separator: " ")
    }
    
}
