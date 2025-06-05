//
//  AccountSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 23/07/2024.
//

import CoreData
import SwiftUI

struct AccountListItem: View {
    var platform: StoredPlatform? = nil
    private var platformIsTwitter: Bool
    private var accountName: String
    private var platformName: String
    var context: NSManagedObjectContext
    private var missing: Bool = false


    init(
        platform: StoredPlatform?,
         context: NSManagedObjectContext,
         platformsVault: Vault_V1_Token? = nil,
         missing: Bool = false
    ) {
        if platformsVault != nil {
            self.accountName = platformsVault?.accountIdentifier ?? "Unknown account"
            self.platformName = platformsVault?.platform ?? ""
        }
        else {
            self.platform = platform
            self.accountName = platform?.account ?? "Unknown account"
            self.platformName = platform?.name ?? "Unknown platform"
        }
        self.platformIsTwitter = platformName == "twitter"
        self.context = context
        self.missing = missing
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
                if !(platform?.isMissing ?? true) {
                    Image(systemName: "checkmark.circle").foregroundStyle(
                        Color.green)
                } else {
                    Image(systemName: "x.circle").foregroundStyle(Color.red)
                }

            }
        }
    }
}

struct SelectAccountSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject private var storedPlatformStore: StoredPlatformStore
    @EnvironmentObject private var platformStore: PlatformStore
//    @State private var publishablePlatforms: [StoredPlatform] = []
//    @State private var allStoredPlatforms: [StoredPlatform] = []
    @State private var publishableAccountsForPlatformName: [StoredPlatform] = []


    @Binding var fromAccount: String
    @Binding var dissmissParent: Bool
    private var platformName: String
    var isSendingMessage: Bool

    var callback: () -> Void = {}

    init(
        filter: String,
        fromAccount: Binding<String>,
        dismissParent: Binding<Bool>,
        isSendingMessage: Bool = false,
        callback: @escaping () -> Void = {}
    ) {
        
        self.isSendingMessage = isSendingMessage

        self.platformName = filter
        _fromAccount = fromAccount
        _dissmissParent = dismissParent

        self.callback = callback

    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List(publishableAccountsForPlatformName, id: \.self.id) { platform in
                    Button(action: {
                        if fromAccount != nil {
                            fromAccount = platform.account
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
            .onAppear {
                // Filter the publishable platforms only for accounts for the same platform
                self.publishableAccountsForPlatformName = storedPlatformStore.storedPlatforms.filter { $0.name == platformName }
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
