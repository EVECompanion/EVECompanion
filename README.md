# EVECompanion iOS App

## About

This project is a companion app for the online Game [EVE Online](https://www.eveonline.com/). It is available for download for free on the [App Store](https://apps.apple.com/de/app/evecompanion/id6504098870).

## Features

- Character Tracking: Monitor your characters' progress and status.
- Skill Queues: Keep an eye on your skill training.
- Wallet Management: Track your ISK and financial transactions.
- Mail Access: Read your EVE Mails on the go.
- Contract Overview: Stay updated on your contracts.
- Jump Clones: Track your jump clones and their locations.
- Industry Jobs: Stay informed about your industry jobs.
- Planetary Colonies: Easily track all your planetary industry colonies.
- Assets: Browse your assets.
- Sovereignty Campaigns: Monitor upcoming and active sovereignty timers.
- Capital Navigation: Plan and calculate jump routes on-device for quick and efficient capital ship travel.
- Item Database: Explore the item database and view detailed information on individual items.
- Skill Notifications: Get push notifications for completed skills and empty skill queue warnings.
- Demo Mode: Explore all features without logging in.

## Static Data Export

This project uses a custom SQLite conversion of the [EVE Online SDE](https://developers.eveonline.com/static-data). The script to process Fuzzwork's SQLite conversion for the app is available at https://github.com/EVECompanion/EVECompanion-SDEProcessor.

### Using the SDE in SwiftUI Previews

To use the processed SDE file in SwiftUI previews, copy the file into the `EVECompanion/Preview Content` directory in Xcode with the filename `EVE.sqlite`.

## Static Data Export Update API

The app does not bundle the SDE files directly, but downloads them from a server. This allows for quick rollout of SDE updates without going through AppStore review. The code for the SDE provider API is available at https://github.com/EVECompanion/EVECompanion-API.
