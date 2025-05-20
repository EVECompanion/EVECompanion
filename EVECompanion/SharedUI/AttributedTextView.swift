//
//  AttributedTextView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.05.24.
//

import SwiftUI
import UIKit

struct AttributedTextView: View {
    
    let attributedString: AttributedString
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var coordinator: Coordinator
    
    init(_ attributedString: AttributedString) {
        self.attributedString = attributedString
    }
    
    var body: some View {
        Text(attributedString)
            .environment(\.openURL, OpenURLAction { url in
                guard let deeplink = Deeplink(url: url) else {
                    return .systemAction
                }
                
                coordinator.push(screen: deeplink.screen)
                return .handled
            })
    }
    
}

#Preview {
    ScrollView {
        AttributedTextView("<font size=\"13\" color=\"#ff999999\"></font><font size=\"12\" color=\"#ffffffff\"><b>Welcome to Pandemic Horde! </b><br><br>THE FIRST THING YOU NEED TO DO IS LOOK AT THE </font><font size=\"12\" color=\"#ffffe400\"><loc><a href=\"https://www.pandemic-horde.org/information/corporationbulletin/index\">CORPORATION BULLETIN</a></loc></font><font size=\"12\" color=\"#ffffffff\"> ON THE HORDE SQUARE WEBSITE AND FOLLOW THOSE INSTRUCTIONS!<br><br>You will need to login first on Horde Square with your new Horde character using </font><font size=\"12\" color=\"#ffffe400\"><a href=\"https://support.eveonline.com/hc/en-us/articles/205381192-Single-Sign-On-SSO-\">EVE Online\'s SSO.</a><br><br></font><font size=\"12\" color=\"#b3ffffff\">The Corporation Bulletin linked above is the most comprehensive and up-to-date source of information for getting set up as a new member. The following are just some highlights:<br><br><br></font><font size=\"12\" color=\"#ffffffff\"><b><u>Wardecs</b></u><br></font><font size=\"12\" color=\"#ffb2b2b2\">Pandemic Horde will always be at war with highsec wardeccers. This means you will <u>NOT</u> be safe any more in highsec as a member of Horde, as wardeccers can shoot you without CONCORD interference. We work around this with our shipping services and neutral hauler alts (</font><font size=\"12\" color=\"#ffffe400\"><loc><a href=\"http://www.youtube.com/watch?v=UG2Lzd7X0rY\">video guide here</a></loc></font><font size=\"12\" color=\"#ffb2b2b2\">).<br><br>You can spot wardeccers in your Local chat window by watching for players with </font><font size=\"12\" color=\"#ffffe400\"><loc><a href=\"http://i.imgur.com/hkKc4YA.png\">this</a></loc></font><font size=\"12\" color=\"#ffb2b2b2\"> icon. Wardeccers are especially common around market hubs and trade routes.<br><br><br></font><font size=\"12\" color=\"#ffffffff\"><b><u>Our Staging &amp; Home</b></u><br></font><font size=\"12\" color=\"#ffb2b2b2\">Pandemic Horde lives in nullsec in Perrigen Falls and our home station is the</font><font size=\"12\" color=\"#ffd98d00\"><a href=\"showinfo:35834//1028081845045\"> </a><a href=\"showinfo:35834//1038457641673\">MJ-5F9 - B E A N S T A R</a></font><font size=\"12\" color=\"#ffb2b2b2\">. This Keepstar is where all the activity and action is, and where you should be moving!<br><br>We have shipping services available to move any assets you will need, although our local market is also well-stocked. On arrival, all new players are additionally given a free care package of ships and skillboks from our NBI volunteers - just ask in the Newbeans channel!<br><br><br></font><font size=\"12\" color=\"#ffffffff\"><b><u>Important Chat Channels</b></u><br></font><font size=\"12\" color=\"#ffb2b2b2\">1. </font><font size=\"12\" color=\"#ff6868e1\"><a href=\"joinChannel:-68532954//None//None\">Newbeans</a></font><font size=\"12\" color=\"#ffb2b2b2\"> To ask for help and guidance. Look for a member of the Newbean Initiative (NBI)!<br>2. </font><font size=\"12\" color=\"#ff6868e1\"><a href=\"joinChannel:player_-68558370\">plusten</a></font><font size=\"12\" color=\"#ffb2b2b2\"> General chat for all alliances in our coalition.<br>3. </font><font size=\"12\" color=\"#ff6868e1\"><a href=\"joinChannel:-88620541//None//None\">Bean-Intel</a></font><font size=\"12\" color=\"#ffb2b2b2\"> Share intel about gatecamps &amp; enemy fleets in our home region.<br><br><br></font><font size=\"12\" color=\"#ffffffff\">Thank you for joining us. Speak to you on comms soon! o7</font>")
    }
}
