//
//  CharacterCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import SwiftUI
import EVECompanionKit
import Kingfisher

struct CharacterCell: View {
    
    @ObservedObject var character: ECKCharacter
    @Binding var selectedCharacter: CharacterSelection
    
    var body: some View {
        if character.hasValidToken {
            NavigationLink(value: AppScreen.characterDetail(character, $selectedCharacter)) {
                contentView
            }
        } else {
            contentView
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        HStack(spacing: 10) {
            ECImage(id: character.id,
                    category: .character)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay {
                    if let info = character.publicInfo {
                        ECImage(id: info.corporationId,
                                category: .corporation)
                            .frame(width: 40, height: 40)
                            .offset(x: -30, y: 30)
                    }
                }
                .overlay {
                    if let info = character.publicInfo,
                       let allianceId = info.allianceId {
                        ECImage(id: allianceId,
                                category: .alliance)
                            .frame(width: 40, height: 40)
                            .offset(x: 30, y: 30)
                    }
                }
            
            VStack(alignment: .leading) {
                Text(character.name)
                    .font(.title2)
                
                if character.hasValidToken {
                    normalContentView
                } else {
                    tokenInvalidView
                }
            }
        }
        .animation(.spring, value: character.initialDataLoadingState)
    }
    
    @ViewBuilder
    var tokenInvalidView: some View {
        VStack {
            Text("This character's login has expired. Please login again or remove this character.")
                .foregroundStyle(Color.secondary)
            
            CharacterLogoutButton(character: character)
        }
    }
    
    @ViewBuilder
    var normalContentView: some View {
        switch character.initialDataLoadingState {
        case .ready,
             .reloading:
            if let skillQueue = character.skillqueue {
                skillQueueView(skillQueue: skillQueue)
            }
            
            HStack {
                if let wallet = character.wallet {
                    factCell(text: "ISK: " + ECFormatters.iskShort(wallet))
                }
                
                if let skillPoints = character.skills?.totalSP {
                    factCell(text: "SP: " + ECFormatters.skillPointsShort(skillPoints))
                }
            }
            
            if let unreadMailCount = character.unreadMailCount, unreadMailCount > 0 {
                unreadMailFactCell(unreadCount: unreadMailCount)
            }
            
        case .loading:
            ProgressView()
            
        case .error:
            RetryButton {
                character.loadInitialData()
            }
            // Workaround to make this work
            // inside of a NavigationLink
            .onTapGesture {
                character.loadInitialData()
            }
            
        }
    }
    
    @ViewBuilder
    func factCell(text: String) -> some View {
        Text(text)
            .padding(5)
            .background(Color(uiColor: .secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    @ViewBuilder
    func unreadMailFactCell(unreadCount: Int) -> some View {
        Label(title: {
                  Text(unreadCount.description)
              },
              icon: {
                  Image(systemName: "envelope")
                    .foregroundStyle(Color.primary)
              })
            .padding(5)
            .background(Color(uiColor: .secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    @ViewBuilder
    func skillQueueView(skillQueue: ECKCharacterSkillQueue) -> some View {
        Group {
            if let currentSkill = skillQueue.first {
                if let remainingTime = currentSkill.remainingTime {
                    let remainingTimeString = " \(ECFormatters.remainingTime(remainingTime: remainingTime))"
                    Text("\(currentSkill.skill.name) \(ECFormatters.skillLevel(level: currentSkill.finishLevel))\(remainingTimeString)")
                } else {
                    Text("\(currentSkill.skill.name) \(ECFormatters.skillLevel(level: currentSkill.finishLevel)) (Paused)")
                }
            } else {
                Text("No skill in training")
            }
        }
        .padding(5)
        .background(Color(uiColor: .secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
}

#Preview {
    List {
        CharacterCell(character: .dummy, selectedCharacter: .constant(.empty))
    }
}
