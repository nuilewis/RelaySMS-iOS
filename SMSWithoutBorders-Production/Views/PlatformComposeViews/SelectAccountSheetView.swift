//
//  AccountSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 23/07/2024.
//

import CoreData
import SwiftUI

struct AccountListItem: View {
    var platform: StoredPlatformsEntity
    private var platformIsTwitter: Bool
    private var accountName: String
    private var platformName: String
    var context: NSManagedObjectContext
    private var tokenExist: Bool = false
    
    
    init(platform: StoredPlatformsEntity, context: NSManagedObjectContext) {
        self.platform = platform
        self.accountName = platform.account ?? "Unknown account"
        self.platformName = platform.name ?? "Unknown platform"
        self.platformIsTwitter = platformName == "twitter"
        self.context = context
        self.tokenExist = StoredTokensEntityManager(context: context).storedTokenExists(forPlarform: platform.id!)
    }
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(RelayColors.colorScheme.primary)
                VStack {
                    Text(platformIsTwitter ? "@\(accountName)" : accountName)
                        .font(RelayTypography.bodyMedium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    Text(platformName.localizedCapitalized)
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .padding()
                if platform.isStoredOnDevice {
                    if tokenExist {
                        Image(systemName: "checkmark.circle").foregroundStyle(
                            Color.green)
                    } else {
                        Image(systemName: "x.circle").foregroundStyle(Color.red)
                    }
                }
            }
        }
    }
}

struct SelectAccountSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    
    @Binding var fromAccount: String
    @Binding var dissmissParent: Bool
    private var platformName: String

    var callback: () -> Void = {}

    init(
        filter: String,
        fromAccount: Binding<String>,
        dismissParent: Binding<Bool>,
        callback: @escaping () -> Void = {}
    ) {
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", filter))

        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", filter))
        
        self.platformName = filter
        _fromAccount = fromAccount
        _dissmissParent = dismissParent

        self.callback = callback
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List(storedPlatforms, id: \.self) { platform in
                    Button(action: {
                        if fromAccount != nil {
                            fromAccount = platform.account!
                        }
                        callback()
                    }) {
                        AccountListItem(
                            platform: platform, context: context)
                    }
                }
            }
            .navigationTitle("\(platformName.localizedCapitalized) accounts")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dissmissParent.toggle()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
        }
    }
}

struct AccountSheetView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        @State var globalDismiss = false
        @State var messagePlatformViewRequested = false
        @State var messagePlatformViewFromAccount: String = ""
        @State var fromAccount: String = ""

        return SelectAccountSheetView(
            filter: "twitter",
            fromAccount: $fromAccount,
            dismissParent: $globalDismiss
        )
        .environment(\.managedObjectContext, container.viewContext)
    }
}
