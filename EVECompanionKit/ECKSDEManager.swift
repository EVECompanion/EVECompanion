//
//  ECKSDEManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 10.05.24.
//

import Foundation
import SQLite

public class ECKSDEManager {
    
    static public let shared: ECKSDEManager = .init()
    
    internal var connection: Connection?
    
    private init() {
        try? setupConnection()
    }
    
    private func getSDEURL() throws -> URL {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return Bundle.main.url(forResource: "EVE", withExtension: "sqlite")!
        }
        #endif
        let documentsDir = try FileManager.default.url(for: .documentDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: true)
        return documentsDir.appendingPathComponent("EVE.sqlite")
    }
    
    private func setupConnection() throws {
        do {
            let sdeURL = try getSDEURL()
            let connection = try Connection(.uri(sdeURL.absoluteString,
                                                 parameters: []),
                                            readonly: true)
            self.connection = connection
        } catch {
            logger.error("Error while connecting to SDE database: \(error)")
            throw error
        }
    }
    
    func updateSDEFile(version: Int, data: Data) throws {
        self.connection = nil
        
        let url = try getSDEURL()
        
        try data.write(to: url, options: .atomic)
        
        try setupConnection()
        UserDefaults.standard.localSDEVersion = version
        NotificationCenter.default.post(.init(name: .sdeUpdated))
    }
    
    public func removeSDEFile() {
        self.connection = nil
        UserDefaults.standard.localSDEVersion = 0
        do {
            let url = try getSDEURL()
            try FileManager.default.removeItem(at: url)
        } catch {
            logger.error("Error resetting database: \(error)")
        }
        
        NotificationCenter.default.post(.init(name: .sdeDeleted))
    }
    
    public typealias FetchedAttribute = (attributeId: Int, attributeName: String)
    let dummyFetchedAttribute: FetchedAttribute = (attributeId: 0, attributeName: "Unknown")
    
    public func getAttribute(id: Int) -> FetchedAttribute {
        let statement = try? connection?.prepare("""
            SELECT
                attributeID,
                attributeName
            FROM
                dgmAttributeTypes
            WHERE
                attributeID = ?
            """, id)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.error("Cannot get attribute with id \(id)")
            return dummyFetchedAttribute
        }
        
        guard let attributeId: Int64 = result[0] as? Int64,
              let attributeName: String = result[1] as? String else {
            logger.error("Unexpected attribute data \(result)")
            return dummyFetchedAttribute
        }
        
        return (attributeId: Int(attributeId), attributeName: attributeName)
    }
    
    typealias FetchedSkill = (skillId: Int,
                              skillName: String,
                              category: String,
                              primaryAttribute: String,
                              secondaryAttribute: String,
                              multiplier: Double)
    
    static let dummyFetchedSkill = (0, 
                                    "Unknown Skill",
                                    "Unknown Category",
                                    "",
                                    "",
                                    0.0)
    
    internal func getAllSkills() -> [FetchedSkill] {
        let statement = try? connection?.prepare("""
                                           SELECT t.typeID,
                                           t.typeName AS skillName,
                                           g.groupName,
                                           (SELECT attributeName
                                               FROM dgmAttributeTypes AS d2
                                               WHERE d2.attributeID= (
                                                   SELECT COALESCE(d.valueInt, d.valueFloat)
                                                   FROM dgmTypeAttributes AS d
                                                   WHERE d.typeID=t.typeID AND d.attributeID=180))
                                           AS PrimaryAttribute,
                                           (SELECT attributeName
                                               FROM dgmAttributeTypes AS d2
                                               WHERE d2.attributeID=(
                                                   SELECT COALESCE(d.valueInt, d.valueFloat)
                                                   FROM dgmTypeAttributes AS d
                                                   WHERE d.typeID=t.typeID AND d.attributeID=181))
                                           AS SecondaryAttribute,
                                           (SELECT d.valueFloat
                                           FROM dgmTypeAttributes AS d
                                           WHERE d.typeID=t.typeID AND d.attributeID=275) AS Multiplier
                                           FROM invTypes AS t
                                           LEFT JOIN invGroups AS g ON g.groupID = t.groupID
                                           LEFT JOIN invCategories AS c ON c.categoryID = g.categoryID
                                           WHERE g.categoryID = 16 AND t.marketGroupID IS NOT NULL
        """)
        
        let iterator = try? statement?.run().makeIterator()
        
        guard let iterator else {
            return []
        }
        
        return iterator.compactMap { row in
            self.parseSkill(row: row)
        }
    }
    
    internal func getSkill(skillId: Int) -> FetchedSkill {
        let statement = try? connection?.prepare("""
                                           SELECT t.typeID,
                                           t.typeName AS skillName,
                                           g.groupName,
                                           (SELECT attributeName
                                               FROM dgmAttributeTypes AS d2
                                               WHERE d2.attributeID= (
                                                   SELECT COALESCE(d.valueInt, d.valueFloat)
                                                   FROM dgmTypeAttributes AS d
                                                   WHERE d.typeID=t.typeID AND d.attributeID=180))
                                           AS PrimaryAttribute,
                                           (SELECT attributeName
                                               FROM dgmAttributeTypes AS d2
                                               WHERE d2.attributeID=(
                                                   SELECT COALESCE(d.valueInt, d.valueFloat)
                                                   FROM dgmTypeAttributes AS d
                                                   WHERE d.typeID=t.typeID AND d.attributeID=181))
                                           AS SecondaryAttribute,
                                           (SELECT d.valueFloat
                                           FROM dgmTypeAttributes AS d
                                           WHERE d.typeID=t.typeID AND d.attributeID=275) AS Multiplier
                                           FROM invTypes AS t
                                           LEFT JOIN invGroups AS g ON g.groupID = t.groupID
                                           LEFT JOIN invCategories AS c ON c.categoryID = g.categoryID
                                           WHERE g.categoryID = 16 AND t.marketGroupID IS NOT NULL AND t.typeID = ?
        """, skillId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        return parseSkill(row: result)
    }
    
    private func parseSkill(row: [(any Binding)?]?) -> FetchedSkill {
        guard let row else {
            logger.warning("No skill fetch result set")
            return Self.dummyFetchedSkill
        }
        
        guard let skillId: Int64 = row[0] as? Int64,
              let skillName: String = row[1] as? String,
              let category: String = row[2] as? String,
              let primaryAttribute: String = row[3] as? String,
              let secondaryAttribute: String = row[4] as? String,
              let multiplier: Double = row[5] as? Double else {
            logger.error("Unexpected skill data \(row)")
            return Self.dummyFetchedSkill
        }
                
        return (Int(skillId),
                skillName,
                category,
                primaryAttribute,
                secondaryAttribute,
                multiplier)
    }
    
    typealias FetchedStation = (stationId: Int,
                                solarSystemId: Int,
                                stationName: String)
    
    static let dummyFetchedStation: FetchedStation = (0,
                                                      0,
                                                      "Unknown Station")
    
    internal func getStation(stationId: Int) -> FetchedStation {
        let statement = try? connection?.prepare("SELECT stationID, solarSystemID, stationName FROM staStations WHERE stationID = ?",
                                                 stationId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.warning("No station fetch result set for id \(stationId)")
            return Self.dummyFetchedStation
        }
        
        guard let stationId: Int64 = result[0] as? Int64,
              let solarSystemId: Int64 = result[1] as? Int64,
              let stationName: String = result[2] as? String else {
            logger.error("Unexpected station data \(result)")
            return Self.dummyFetchedStation
        }
        
        return (Int(stationId),
                Int(solarSystemId),
                stationName)
    }
    
    typealias FetchedSolarSystem = (regionId: Int,
                                    constellationId: Int,
                                    solarSystemId: Int,
                                    solarSystemName: String,
                                    security: Double,
                                    x: Float,
                                    y: Float,
                                    z: Float,
                                    sunTypeId: Int?)
    
    static let dummyFetchedSolarSystem: FetchedSolarSystem = (0,
                                                              0,
                                                              0,
                                                              "Unknown Solar System",
                                                              0.0,
                                                              0,
                                                              0,
                                                              0,
                                                              sunTypeId: 45032)
    
    internal func getSolarSystem(solarSystemId: Int) -> FetchedSolarSystem {
        let statement = try? connection?.prepare("SELECT regionID, constellationID, solarSystemID, solarSystemName, security, x, y, z, sunTypeID FROM mapSolarSystems WHERE solarSystemID = ?", solarSystemId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.warning("No solar system fetch result set for id \(solarSystemId)")
            return Self.dummyFetchedSolarSystem
        }
        
        return rowToSolarSystem(row: result)
    }
    
    private func rowToSolarSystem(row: [(any Binding)?]) -> FetchedSolarSystem {
        guard let regionId: Int64 = row[0] as? Int64,
              let constellationId: Int64 = row[1] as? Int64,
              let solarSystemId: Int64 = row[2] as? Int64,
              let solarSystemName: String = row[3] as? String,
              let security: Double = row[4] as? Double,
              let x: Double = row[5] as? Double,
              let y: Double = row[6] as? Double,
              let z: Double = row[7] as? Double else {
            logger.error("Unexpected solar system data \(row)")
            return Self.dummyFetchedSolarSystem
        }
        
        let sunTypeId: Int?
        
        if let sunId = row[8] as? Int64 {
            sunTypeId = Int(sunId)
        } else {
            sunTypeId = nil
        }
        
        return (Int(regionId),
                Int(constellationId),
                Int(solarSystemId),
                solarSystemName,
                security,
                Float(x),
                Float(y),
                Float(z),
                sunTypeId)
    }
    
    typealias FetchedItem = (typeId: Int,
                             name: String,
                             description: String?,
                             mass: Float?,
                             volume: Float?,
                             capacity: Float?,
                             radius: Float?,
                             iconId: Int?)
    
    static let dummyFetchedItem: FetchedItem = (typeId: 0,
                                                name: "Unknown item",
                                                description: nil,
                                                mass: nil,
                                                volume: nil,
                                                capacity: nil,
                                                radius: nil,
                                                iconId: nil)
    
    internal func getItem(typeId: Int) -> FetchedItem {
        let statement = try? connection?.prepare("SELECT typeID, typeName, description, mass, volume, capacity, radius, iconID FROM invTypes WHERE typeID = ?", typeId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.warning("No item fetch result set for id \(typeId)")
            return Self.dummyFetchedItem
        }
        
        return parseItem(row: result)
    }
    
    internal func itemSearch(text: String) -> [ECKItem] {
        do {
            let statement = try connection?.prepare("""
                SELECT
                    typeID,
                    typeName, 
                    description, 
                    mass, 
                    volume, 
                    capacity, 
                    radius,
                    iconID
                FROM
                    invTypes
                where 
                    typeName LIKE "%" || ? || "%"
                    AND published = 1
                ORDER BY 
                    typeName
                LIMIT 
                    50
            """, text)
            
            guard let result = try statement?.run() else {
                return []
            }
            
            let fetchedItems = result.map({ parseItem(row: $0) })
            
            return fetchedItems.map({ ECKItem(itemData: $0) })
        } catch {
            logger.error("Cannot get items with search string \(text): \(error)")
            return []
        }
    }
    
    internal func items(marketGroupId: Int) -> [ECKItem] {
        do {
            let statement = try connection?.prepare("""
                SELECT
                    typeID,
                    typeName, 
                    description, 
                    mass, 
                    volume, 
                    capacity, 
                    radius,
                    iconID
                FROM
                    invTypes
                WHERE
                    marketGroupID = ?
            """, marketGroupId)
            
            guard let result = try statement?.run() else {
                return []
            }
            
            let fetchedItems = result.map({ parseItem(row: $0) })
            
            return fetchedItems.map({ ECKItem(itemData: $0) })
        } catch {
            logger.error("Cannot get items with market group id \(String(describing: marketGroupId)): \(error)")
            return []
        }
    }
    
    private func parseItem(row: [(any Binding)?]) -> FetchedItem {
        guard let typeId = row[0] as? Int64 else {
            logger.error("Unexpected item data \(row)")
            return Self.dummyFetchedItem
        }
        
        guard let name = row[1] as? String else {
            logger.error("Unexpected item data \(row)")
            return Self.dummyFetchedItem
        }
        
        let description: String? = row[2] as? String
        
        let mass: Float?
        if let massFloat = row[3] as? Float64 {
            mass = Float(massFloat)
        } else {
            mass = nil
        }
        
        let volume: Float?
        if let volumeFloat = row[4] as? Float64 {
            volume = Float(volumeFloat)
        } else {
            volume = nil
        }
        
        let capacity: Float?
        if let capacityFloat = row[5] as? Float64 {
            capacity = Float(capacityFloat)
        } else {
            capacity = nil
        }
        
        let radius: Float?
        if let radiusFloat = row[6] as? Float64 {
            radius = Float(radiusFloat)
        } else {
            radius = nil
        }
        
        let iconID: Int?
        if let iconIDInt = row[7] as? Int64 {
            iconID = Int(iconIDInt)
        } else {
            iconID = nil
        }
        
        return (Int(typeId),
                name,
                description,
                mass,
                volume,
                capacity,
                radius,
                iconID)
    }
    
    static let dummyRegionName: String = "Unknown Region"
    
    internal func getRegionName(regionId: Int) -> String {
        let statement = try? connection?.prepare("SELECT regionName FROM mapRegions WHERE regionID = ?", regionId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.warning("No region fetch result set for id \(regionId)")
            return Self.dummyRegionName
        }
        
        guard let name = result[0] as? String else {
            logger.error("Unexpected region data \(result)")
            return Self.dummyRegionName
        }
        
        return name
    }
    
    static let dummyConstellationName: String = "Unknown Constellation"
    
    internal func getConstellationName(constellationId: Int) -> String {
        let statement = try? connection?.prepare("SELECT constellationName FROM mapConstellations WHERE constellationID = ?", constellationId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.warning("No constellation fetch result set for id \(constellationId)")
            return Self.dummyConstellationName
        }
        
        guard let name = result[0] as? String else {
            logger.error("Unexpected constellation data \(result)")
            return Self.dummyConstellationName
        }
        
        return name
    }
    
    typealias FetchedFaction = (factionId: Int,
                                name: String,
                                description: String,
                                iconId: Int?)
    
    static let dummyFetchedFaction: FetchedFaction = (0,
                                                      "Unknown Faction",
                                                      "",
                                                      nil)
    
    internal func getFaction(factionId: Int) -> FetchedFaction {
        let statement = try? connection?.prepare("SELECT factionName, description, iconId FROM chrFactions WHERE factionID = ?", factionId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.warning("No faction fetch result set for id \(factionId)")
            return Self.dummyFetchedFaction
        }
        
        guard let factionName: String = result[0] as? String,
              let description: String = result[1] as? String else {
            logger.error("Unexpected faction data \(result)")
            return Self.dummyFetchedFaction
        }
        
        let iconID: Int?
        if let iconIDInt = result[2] as? Int64 {
            iconID = Int(iconIDInt)
        } else {
            iconID = nil
        }
        
        return (factionId, factionName, description, iconID)
    }
    
    typealias FetchedIndustryActivity = (name: String,
                                         description: String,
                                         icon: String?)
    
    static let dummyFetchedIndustryActivity: FetchedIndustryActivity = (
                                                      "Unknown Activity",
                                                      "",
                                                      nil)
    
    internal func getIndustryActivity(activityId: Int) -> FetchedIndustryActivity {
        let statement = try? connection?.prepare("SELECT activityName, description, iconNo FROM ramActivities WHERE activityID = ?", activityId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.warning("No industry activity fetch result set for id \(activityId)")
            return Self.dummyFetchedIndustryActivity
        }
        
        guard let activityName: String = result[0] as? String,
              let description: String = result[1] as? String else {
            logger.error("Unexpected industry activity data \(result)")
            return Self.dummyFetchedIndustryActivity
        }
        
        let iconNo: String?
        if let iconIDInt = result[2] as? String {
            iconNo = iconIDInt
        } else {
            iconNo = nil
        }
        
        return (activityName, description, iconNo)
    }
    
    typealias SystemInRangeResult = (systemAId: Int,
                                     systemBId: Int,
                                     distance: Double)
    
    func capitalHSToLSJumpDistances() -> [SystemInRangeResult] {
        return capitalJumpDistances(table: "mapCapitalHSJumpDistances")
    }
    
    func capitalLSJumpDistances() -> [SystemInRangeResult] {
        return capitalJumpDistances(table: "mapCapitalJumpDistances")
    }
    
    private func capitalJumpDistances(table: String) -> [SystemInRangeResult] {
        do {
            let statement = try connection?.prepare("""
                                SELECT
                                    startSystemID,
                                    destinationSystemID,
                                    distance
                                FROM
                                    \(table)
                            """)
            
            let result = try statement?.run()
            
            guard let result else {
                return []
            }
            
            return result.compactMap { row -> SystemInRangeResult? in
                guard let systemAId: Int64 = row[0] as? Int64,
                      let systemBId: Int64 = row[1] as? Int64,
                      let distance: Double = row[2] as? Double else {
                    logger.error("Unexpected system range data \(result)")
                    return nil
                }
                
                return (systemAId: Int(systemAId), systemBId: Int(systemBId), distance: distance)
            }
        } catch {
            logger.error(error)
            return []
        }
    }
    
    public typealias JumpCapableShip = (typeId: Int,
                                        name: String,
                                        groupId: Int,
                                        groupName: String,
                                        baseJumpRange: Double,
                                        fuelConsumption: Double)
    
    static let dummyJumpCapableShip: JumpCapableShip = (typeId: 0,
                                                        name: "Unknown ship",
                                                        groupId: 0,
                                                        groupName: "Unknown",
                                                        baseJumpRange: 0,
                                                        fuelConsumption: 0)
    
    func jumpCapableShips() -> [JumpCapableShip] {
        do {
            let statement = try connection?.prepare("""
            SELECT
                invTypes.typeID,
                invTypes.typeName,
                invGroups.groupID,
                invGroups.groupName,
                jumpRangeData.valueFloat AS jumpRange,
                jumpFuelConsumption.valueFloat AS jumpFuelConsumption
            FROM
                dgmTypeAttributes
                INNER JOIN invTypes ON dgmTypeAttributes.typeID = invTypes.typeID
                INNER JOIN invGroups ON invTypes.groupID = invGroups.groupID
                INNER JOIN dgmTypeAttributes AS jumpRangeData ON jumpRangeData.typeID = invTypes.typeID
                INNER JOIN dgmTypeAttributes AS jumpFuelConsumption ON jumpFuelConsumption.typeID = invTypes.typeID
            WHERE
                dgmTypeAttributes.attributeID = 861
                AND dgmTypeAttributes.valueFloat = 1.0
                AND jumpRangeData.attributeID = 867
                AND jumpFuelConsumption.attributeID = 868
                AND invTypes.published = 1
            ORDER BY
                invGroups.groupName,
                invTypes.typeName
            """)
            
            let result = try statement?.run()
            
            guard let result else {
                return []
            }
            
            return result.compactMap { row -> JumpCapableShip? in
                parseJumpCapableShip(row: row)
            }
        } catch {
            logger.error(error)
            return []
        }
    }
    
    func jumpCapableShip(with id: Int) -> JumpCapableShip {
        do {
            let statement = try connection?.prepare("""
            SELECT
                invTypes.typeID,
                invTypes.typeName,
                invGroups.groupID,
                invGroups.groupName,
                jumpRangeData.valueFloat AS jumpRange,
                jumpFuelConsumption.valueFloat AS jumpFuelConsumption
            FROM
                dgmTypeAttributes
                INNER JOIN invTypes ON dgmTypeAttributes.typeID = invTypes.typeID
                INNER JOIN invGroups ON invTypes.groupID = invGroups.groupID
                INNER JOIN dgmTypeAttributes AS jumpRangeData ON jumpRangeData.typeID = invTypes.typeID
                INNER JOIN dgmTypeAttributes AS jumpFuelConsumption ON jumpFuelConsumption.typeID = invTypes.typeID
            WHERE
                invTypes.typeID = ?
                AND dgmTypeAttributes.attributeID = 861
                AND dgmTypeAttributes.valueFloat = 1.0
                AND jumpRangeData.attributeID = 867
                AND jumpFuelConsumption.attributeID = 868
                AND invTypes.published = 1
            ORDER BY
                invGroups.groupName,
                invTypes.typeName
            """, id)
            
            let result = try statement?.makeIterator().failableNext()
            
            guard let result else {
                return Self.dummyJumpCapableShip
            }
            
            return parseJumpCapableShip(row: result) ?? Self.dummyJumpCapableShip
        } catch {
            logger.error(error)
            return Self.dummyJumpCapableShip
        }
    }
    
    private func parseJumpCapableShip(row: Statement.Element) -> JumpCapableShip? {
        guard let typeId: Int64 = row[0] as? Int64,
              let typeName: String = row[1] as? String,
              let groupId: Int64 = row[2] as? Int64,
              let groupName: String = row[3] as? String,
              let jumpRange: Double = row[4] as? Double,
              let fuelConsumption: Double = row[5] as? Double else {
            logger.error("Unexpected jump capable ship data \(row)")
            return nil
        }
        
        return (typeId: Int(typeId),
                name: typeName,
                groupId: Int(groupId),
                groupName: groupName,
                baseJumpRange: jumpRange,
                fuelConsumption: fuelConsumption)
    }
    
    public func searchCapitalJumpDestinationSystems(_ text: String) -> [ECKSolarSystem] {
        do {
            let statement = try connection?.prepare("""
        SELECT
            regionID,
            constellationID,
            solarSystemID,
            solarSystemName,
            security,
            x,
            y,
            z,
            sunTypeID
        FROM
            mapSolarSystems
        WHERE
            regionID != 10000070 
            AND regionID != 10000019 
            AND regionID != 10000004 
            AND regionID != 10000017 
            AND regionID < 11000001
            AND solarSystemName LIKE "%" || ? || "%"
        ORDER BY
            solarSystemName
        LIMIT 
            50
        """, text)
            
            let result = try statement?.run()
            
            guard let result else {
                return []
            }
            
            let systems: [FetchedSolarSystem] = result.map { row in
                return rowToSolarSystem(row: row)
            }
            
            return systems.map({ .init(fetchedSolarSystem: $0) })
        } catch {
            logger.error(error)
            return []
        }
    }
    
    typealias ItemCategory = (category: String, group: String)
    static let dummyItemCategory: ItemCategory = (category: "Unknown", group: "Unknown")
    
    func itemCategory(_ itemId: Int) -> ItemCategory {
        do {
            let statement = try connection?.prepare("""
            SELECT
                invCategories.categoryName,
                invGroups.groupName
            FROM
                invTypes
                INNER JOIN invGroups ON invGroups.groupID = invTypes.groupID
                INNER JOIN invCategories ON invCategories.categoryID = invGroups.categoryID
            WHERE
                invTypes.typeID = ?    
            """, itemId)
            
            guard let result = try statement?.makeIterator().failableNext() else {
                return Self.dummyItemCategory
            }
            
            guard let category: String = result[0] as? String,
                  let group: String = result[1] as? String else {
                logger.error("Unexpected item category data \(result)")
                return Self.dummyItemCategory
            }
            
            return (category: category, group: group)
        } catch {
            logger.error("Cannot get category for item \(itemId): \(error)")
            return Self.dummyItemCategory
        }
    }
    
    public typealias ItemTraitEntry = (traitId: Int, bonus: Double?, bonusText: String, unit: EVEUnit?)
    public typealias ItemTraitGroup = (skillId: Int?, skillName: String?, entries: [ItemTraitEntry])
    public typealias ItemTraits = [ItemTraitGroup]
    func itemTraits(_ itemId: Int) -> ItemTraits {
        do {
            let statement = try connection?.prepare("""
            SELECT
                invTypes.typeID as skillID,
                invTypes.typeName as skillName,
                invTraits.traitID,
                invTraits.bonus,
                invTraits.bonusText,
                eveUnits.unitName
            FROM
                invTraits
                LEFT OUTER JOIN invTypes ON invTraits.skillID = invTypes.typeID
                LEFT OUTER JOIN eveUnits on invTraits.unitID = eveUnits.unitID
            WHERE
                invTraits.typeID = ?
            ORDER BY
                invTraits.skillID,
                invTraits.traitID
            """, itemId)
            
            guard let result = try statement?.run() else {
                return []
            }
            
            var traits: ItemTraits = []
            
            for row in result {
                let skillId: Int?
                if let skill = row[0] as? Int64 {
                    skillId = Int(skill)
                } else {
                    skillId = nil
                }
                let skillName: String? = row[1] as? String
                guard let traitIdInt64: Int64 = row[2] as? Int64 else {
                    logger.info("Trait ID for row \(row) is null.")
                    continue
                }
                let traitId: Int = Int(traitIdInt64)
                let bonus: Double? = row[3] as? Double
                guard let bonusText: String = row[4] as? String else {
                    logger.info("Bonus text for row \(row) is null.")
                    continue
                }
                let unitName: String? = row[5] as? String
                
                let unit: EVEUnit?
                if let unitName {
                    unit = EVEUnit(unitName)
                } else {
                    unit = nil
                }
                
                let traitEntry = (traitId: traitId,
                                  bonus: bonus,
                                  bonusText: bonusText,
                                  unit: unit)
                if let existingTraitGroup = traits.enumerated().first(where: { $0.element.skillName == skillName }) {
                    traits[existingTraitGroup.offset] = (skillId: skillId,
                                                         skillName: skillName,
                                                         entries: traits[existingTraitGroup.offset].entries + [traitEntry])
                } else {
                    traits.append((skillId: skillId,
                                   skillName: skillName,
                                   entries: [traitEntry]))
                }
            }
            
            return traits
        } catch {
            logger.error("Cannot get traits for item \(itemId): \(error)")
            return []
        }
    }
    
    public typealias ItemAttribute = (id: Int, name: String, displayName: String, value: Float, unit: EVEUnit?)
    public typealias ItemAttributeCategory = (name: String, attributes: [ItemAttribute])
    public typealias ItemAttributes = [ItemAttributeCategory]
    func itemAttributes(_ itemId: Int) -> ItemAttributes {
        do {
            let statement = try connection?.prepare("""
                SELECT
                    dgmAttributeTypes.attributeID,
                    dgmAttributeTypes.attributeName,
                    dgmAttributeTypes.displayName,
                    dgmTypeAttributes.valueFloat,
                    dgmAttributeCategories.categoryName,
                    eveUnits.unitName
                FROM
                    dgmTypeAttributes
                    INNER JOIN dgmAttributeTypes ON dgmTypeAttributes.attributeID = dgmAttributeTypes.attributeID
                    INNER JOIN dgmAttributeCategories ON dgmAttributeTypes.categoryID = dgmAttributeCategories.categoryID
                    INNER JOIN eveUnits ON dgmAttributeTypes.unitID = eveUnits.unitID
                WHERE
                    dgmTypeAttributes.typeID = ?
                    AND dgmAttributeTypes.attributeName IS NOT NULL
                    AND dgmAttributeTypes.published = 1
                    AND categoryName != "NULL"
                    AND dgmAttributeTypes.categoryID != 8
                ORDER BY
                    dgmAttributeCategories.categoryID,
                    dgmAttributeTypes.attributeID
            """, itemId)
            
            guard let result = try statement?.run() else {
                return []
            }
            
            var attributes: ItemAttributes = []
            
            for row in result {
                guard let attributeId: Int64 = row[0] as? Int64,
                      let attributeName: String = row[1] as? String,
                      let attributeDisplayName: String = row[2] as? String,
                      let attributeValue: Float64 = row[3] as? Float64,
                      let categoryName: String = row[4] as? String else {
                          logger.info("Unexpected item attribute data \(row)")
                          continue
                }
                
                let unitName: String? = row[5] as? String
                
                let unit: EVEUnit?
                if let unitName {
                    unit = EVEUnit(unitName)
                } else {
                    unit = nil
                }
                
                let attribute: ItemAttribute = (id: Int(attributeId),
                                                name: attributeName,
                                                displayName: attributeDisplayName,
                                                value: Float(attributeValue),
                                                unit: unit)
                
                if let existingAttributeCategory = attributes.enumerated().first(where: { $0.element.name == categoryName }) {
                    attributes[existingAttributeCategory.offset] = (name: categoryName,
                                                                    attributes: attributes[existingAttributeCategory.offset].attributes + [attribute])
                } else {
                    attributes.append((name: categoryName, attributes: [attribute]))
                }
            }
            
            return attributes
        } catch {
            logger.error("Cannot get attributes for item \(itemId): \(error)")
            return []
        }
    }
    
    func marketGroup(id: Int) -> ECKMarketGroup? {
        do {
            let statement = try connection?.prepare("""
                SELECT
                    marketGroupID,
                    marketGroupName,
                    description,
                    hasTypes
                FROM
                    invMarketGroups
                WHERE
                    marketGroupID = ?
            """, id)
            
            guard let result = try statement?.run().makeIterator().failableNext() else {
                return nil
            }
            
            return parseMarketGroup(row: result)
        } catch {
            logger.error("Cannot get market group with id \(id): \(error)")
            return nil
        }
    }
    
    func marketGroups(parentGroupId: Int?) -> [ECKMarketGroup] {
        do {
            let filter: String
            if let parentGroupId {
                filter = "= \(parentGroupId)"
            } else {
                filter = "IS NULL"
            }
            
            let statement = try connection?.prepare("""
                SELECT
                    marketGroupID,
                    marketGroupName,
                    description,
                    hasTypes
                FROM
                    invMarketGroups
                WHERE
                    parentGroupID \(filter)
                ORDER BY 
                    marketGroupName
            """)
            
            guard let result = try statement?.run() else {
                return []
            }
            
            return result.compactMap { row in
                return parseMarketGroup(row: row)
            }
        } catch {
            logger.error("Cannot get market groups with parent id \(String(describing: parentGroupId)): \(error)")
            return []
        }
    }
    
    private func parseMarketGroup(row: [(any Binding)?]) -> ECKMarketGroup? {
        guard let id: Int64 = row[0] as? Int64,
              let name: String = row[1] as? String,
              let description: String = row[2] as? String,
              let hasTypes: Int64 = row[3] as? Int64 else {
                  logger.info("Unexpected market group data \(row)")
                  return nil
        }
        
        return .init(id: Int(id), name: name, description: description, hasTypes: hasTypes != 0)
    }
    
    public func groupName(for id: Int) -> String {
        do {
            let statement = try connection?.prepare("""
                SELECT groupName FROM invGroups where groupID = ?
            """, id)
            
            guard let result = try statement?.run().makeIterator().failableNext() else {
                return "Unknown"
            }
            
            return (result[0] as? String) ?? "Unknown"
        } catch {
            logger.error("Cannot get group name with id \(id): \(error)")
            return "Unknown"
        }
    }
    
    public typealias RequiredSkill = (skillId: Int, requiredLevel: Int)
    public func requiredSkills(typeId: Int) -> [RequiredSkill] {
        do {
            let statement = try connection?.prepare("""
                SELECT
                    dgmTypeAttributes.valueFloat as skillID,
                    (
                        SELECT
                            valueFloat AS requiredSkillLevel
                        FROM
                            dgmTypeAttributes AS skillRequirements
                        WHERE
                            skillRequirements.attributeID = dgmSkillRequirementsAttributeMapping.requirementAttributeID
                            AND skillRequirements.typeID = ?
                    ) AS requiredSkillLevel
                FROM
                    dgmAttributeTypes
                    INNER JOIN dgmTypeAttributes ON dgmAttributeTypes.attributeID = dgmTypeAttributes.attributeID
                    INNER JOIN dgmSkillRequirementsAttributeMapping ON dgmAttributeTypes.attributeID = dgmSkillRequirementsAttributeMapping.displayAttributeID
                WHERE
                    dgmTypeAttributes.typeID = ?
                """, typeId, typeId)
            
            guard let result = try statement?.run() else {
                return []
            }
            
            return result.compactMap { row in
                guard let skillId: Float64 = row[0] as? Float64,
                      let requiredLevel: Float64 = row[1] as? Float64 else {
                          logger.info("Unexpected required skill data \(row)")
                          return nil
                }
                
                return (skillId: Int(skillId), requiredLevel: Int(requiredLevel))
            }
        } catch {
            logger.error("Cannot get required skill for type id \(typeId): \(error)")
            return []
        }
    }
    
    typealias FetchedSchematicData = (typeId: Int,
                                      quantity: Int,
                                      isInput: Bool)
    
    static let dummyFetchedSchematicData: FetchedSchematicData = (typeId: 99999999, quantity: 0, isInput: false)
    
    internal func getSchematicData(schematicId: Int) -> (cycleTime: Int, inouts: [FetchedSchematicData]) {
        let statement = try? connection?.prepare("SELECT typeId, quantity, isInput, cycleTime FROM (planetSchematicsTypeMap LEFT JOIN planetSchematics ON planetSchematicsTypeMap.schematicID = planetSchematics.schematicID) WHERE planetSchematicsTypeMap.schematicID = ?", schematicId)
        
        let iterator = try? statement?.run().makeIterator()
        
        guard let iterator else {
            logger.error("Unexpected schematic data for \(schematicId)")
            return (cycleTime: 0, inouts: [])
        }
        
        var fetchedCycleTime: Int64?
        
        let inouts = iterator.map { row in
            guard let typeId: Int64 = row[0] as? Int64,
                  let quantity: Int64 = row[1] as? Int64,
                  let isInput: Int64 = row[2] as? Int64,
                  let cycleTime: Int64 = row[3] as? Int64 else {
                logger.error("Unexpected schematic data for \(schematicId): \(row)")
                return Self.dummyFetchedSchematicData
            }
            
            fetchedCycleTime = cycleTime
                    
            return (Int(typeId),
                    Int(quantity),
                    Bool(truncating: isInput as NSNumber))
        }
        
        return (cycleTime: Int(fetchedCycleTime ?? 0), inouts: inouts)
    }
    
    typealias FetchedPlanet = (typeId: Int, name: String)
    
    static let dummyFetchedPlanet: FetchedPlanet = (typeId: 56018, name: "Unknown Planet")
    
    internal func getPlanet(planetId: Int) -> FetchedPlanet {
        let statement = try? connection?.prepare("SELECT itemName, typeID FROM mapDenormalize WHERE itemID = ?", planetId)
        
        let result = try? statement?.run().makeIterator().failableNext()
        
        guard let result else {
            logger.warning("No planet fetch result set for id \(planetId)")
            return Self.dummyFetchedPlanet
        }
        
        guard let name: String = result[0] as? String,
              let typeId: Int64 = result[1] as? Int64 else {
            logger.error("Unexpected planet data \(result)")
            return Self.dummyFetchedPlanet
        }
        
        return (typeId: Int(typeId), name: name)
    }
    
    internal func getAttributeValue(attributeId: Int, typeId: Int) -> Float? {
        let statement = try? connection?.prepare("SELECT valueFloat FROM dgmTypeAttributes WHERE attributeID = 1683 AND typeID = ?", attributeId)
        let result = try? statement?.run().makeIterator().failableNext()
        let value = result?[0] as? Float64
        
        if let value {
            return Float(value)
        } else {
            return getAttributeDefaultValue(attributeId: attributeId)
        }
    }
    
    internal func getAttributeDefaultValue(attributeId: Int) -> Float? {
        let statement = try? connection?.prepare("SELECT defaultValue FROM dgmAttributeTypes WHERE attributeID = ?", attributeId)
        let result = try? statement?.run().makeIterator().failableNext()
        let value = result?[0] as? Float64
        if let value {
            return Float(value)
        } else {
            return nil
        }
    }
    
    typealias FetchedEffect = (effectId: Int, effectName: String, effectCategory: Int?, modifierInfo: String)
    internal func getEffects(for typeId: Int) -> [FetchedEffect] {
        do {
            let statement = try connection?.prepare("""
            SELECT
                dgmEffects.effectID,
                dgmEffects.effectName,
                dgmEffects.effectCategory,
                dgmEffects.modifierInfo
            FROM
                dgmTypeEffects
                LEFT OUTER JOIN dgmEffects ON dgmTypeEffects.effectID = dgmEffects.effectID
            WHERE
                dgmTypeEffects.typeID = ?
            """, typeId)
            
            guard let result = try statement?.run() else {
                return []
            }
            
            return result.compactMap { row -> FetchedEffect? in
                guard let effectId: Int64 = row[0] as? Int64,
                      let effectName: String = row[1] as? String,
                      let modifierInfo: String = row[3] as? String else {
                          logger.info("Unexpected effect data \(row)")
                          return nil
                }
                
                let effectCategory: Int?
                if let category: Int64 = row[2] as? Int64 {
                    effectCategory = Int(category)
                } else {
                    effectCategory = nil
                }
                
                return (effectId: Int(effectId),
                        effectName: effectName,
                        effectCategory: effectCategory,
                        modifierInfo: modifierInfo)
            }
        } catch {
            logger.error("Error fetching effects for type \(typeId): \(error)")
            return []
        }
    }
    
}
