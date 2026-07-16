import SwiftUI
import UIKit

/// Временный стартовый экран (Фаза 1). Показывает бренд, Device ID для привязки ключа и
/// активацию премиума — этого достаточно, чтобы собрать первый .ipa и проверить лицензию
/// на устройстве. Экран телесуфлёра + BLE к очкам добавляются в следующих фазах.
struct ContentView: View {
    @State private var keyInput = ""
    @State private var premium = PremiumManager.isPremium()
    @State private var toast: String?
    @ObservedObject private var ble = BleManager.shared

    private var deviceId: String { LicenseManager.deviceId() }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    statusCard

                    glassesCard

                    deviceCard

                    activateCard

                    Text("Экран телесуфлёра (превью, авто-скролл) — в следующих сборках. Подключение к G2 и показ текста — экспериментально, проверяется на реальном iPhone.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Whisprompt")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottom) { toastView }
        }
        .navigationViewStyle(.stack)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WHISPROMPT")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(Color(red: 0.33, green: 0.90, blue: 0.48))
            Text("Teleprompter for Even Realities G2")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var statusCard: some View {
        HStack {
            Image(systemName: premium ? "checkmark.seal.fill" : "seal")
                .foregroundColor(premium ? .green : .secondary)
            Text(premium ? "Премиум активен" : "Бесплатная версия")
                .fontWeight(.semibold)
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var glassesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Очки G2").font(.headline)
            HStack(spacing: 8) {
                Circle()
                    .fill(ble.isReady ? Color.green : (ble.isScanning ? Color.orange : Color.gray))
                    .frame(width: 10, height: 10)
                Text(ble.status).font(.subheadline).foregroundColor(.secondary)
                Spacer()
            }
            HStack {
                Button(ble.isScanning || ble.isReady ? "Отключить" : "Подключить") {
                    if ble.isScanning || ble.isReady { ble.disconnect() } else { ble.connect() }
                }
                .buttonStyle(.bordered)
                Button("Тест текста") {
                    ble.showText("Whisprompt на очках.\nТестовый текст телесуфлёра для проверки подключения к G2.",
                                 narrow: false)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!ble.isReady)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var deviceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device ID (для привязки ключа)")
                .font(.caption).foregroundColor(.secondary)
            HStack {
                Text(deviceId)
                    .font(.system(.footnote, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button {
                    UIPasteboard.general.string = deviceId
                    showToast("Device ID скопирован")
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var activateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Активация ключа")
                .font(.headline)
            Text("Ключ покупается в \(LicenseManager.TG_BOT) и привязан к этому устройству.")
                .font(.caption).foregroundColor(.secondary)
            TextField("Вставьте ключ активации", text: $keyInput, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .lineLimit(1...4)
                .padding(10)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(10)
            Button {
                activate()
            } label: {
                Text("Активировать")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            Text(toast)
                .font(.footnote)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.bottom, 24)
                .transition(.opacity)
        }
    }

    private func activate() {
        let ok = LicenseManager.activate(keyInput)
        premium = PremiumManager.isPremium()
        showToast(ok ? "Премиум активирован" : "Ключ недействителен для этого устройства")
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { if toast == message { toast = nil } }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
