# Çizgi Bulmaca — Marka, Ekran Tasarımı & Uyumluluk Rehberi

## 1. Güncellenen Level Yapısı
- **Kolay:** 200+ level
- **Orta:** 200+ level
- **Zor:** 200+ level
- **Toplam:** 600+ level (içerik hattı ile sürekli genişletilebilir)

## 2. Renk Paleti

**Marka Ana Renkleri (varsayılan tema)**
| Rol | Renk | Hex |
|---|---|---|
| Ana Renk (Primary) | Elektrik Mor | `#6C4CF5` |
| İkincil Renk | Mint Yeşil (başarı/tamamlama) | `#3ADEB0` |
| Vurgu Rengi | Sıcak Sarı (yıldız/ödül) | `#FFC93C` |
| Arkaplan (Açık) | Kırık Beyaz | `#F7F6FB` |
| Arkaplan (Koyu) | Gece Lacivert | `#12101C` |
| Uyarı/Hata | Mercan Kırmızı | `#FF5C5C` |

**Kullanıcı Tema Seçenekleri (preset paletler)**
Ana renk (`Primary`) kullanıcı tarafından değiştirilebilir; öneri: 6-8 preset (Mor, Mavi, Turuncu, Pembe, Yeşil, Kırmızı) + custom color picker. Arkaplan/kontrast renkleri sabit kalır, sadece vurgu rengi değişir — bu, marka tutarlılığını korurken kişiselleştirme sağlar.

**Zorluk Renk Kodlaması** (level haritasında modları ayırt etmek için)
- Kolay → Mint Yeşil
- Orta → Sarı/Turuncu
- Zor → Mor/Kırmızı geçişli

## 3. Logo Konsepti

**Yön:** Tek çizgiyle çizilmiş (continuous line) bir figür — oyunun mekaniğini logonun kendisi anlatmalı.

- **İkon fikri:** "Ç" harfinin veya soyut bir düğümün tek çizgiyle, kalınlığı sabit bir stroke ile çizilmesi; çizginin başlangıç noktası bir nokta (dot) ile, bitiş noktası ok ucu/parmak izi ile vurgulanabilir (parmakla çizme hissini korumak için).
- **Stil:** Modern, yuvarlak hatlı (rounded line-cap), minimalist — App Store'daki jenerik puzzle ikonlarından (çok detaylı/3D) ayrışmak için düz/flat + hafif gradient (mor → mint) kullanılabilir.
- **Tipografi:** Yuvarlak hatlı, geometrik sans-serif (ör. Poppins, Baloo 2, Fredoka) — oyunun "eğlenceli ama premium" hissini destekler.
- **Varyasyonlar gerekli:**
  - Uygulama ikonu (arkaplan dolu, metin yok) — 1024×1024
  - Yatay logo (ikon + "Çizgi Bulmaca" yazısı) — splash ekranı için
  - Monokrom versiyon (koyu/açık mod için tek renk)
- **Not:** Nihai logoyu bir tasarımcı/AI görsel aracıyla üretmeniz gerekiyor; bu belge yönlendirici tasarım brief'i olarak kullanılabilir.

## 4. Reklam Entegrasyonu

**SDK:** Google AdMob (Flutter için `google_mobile_ads` paketi)

**Reklam Türleri ve Yerleşimi**
- **Interstitial:** Her level tamamlandığında (2-3 level'da bir olacak şekilde A/B test edilmesi önerilir — her level'da göstermek erken churn riski taşır)
- **Rewarded:** İpucu kazanma, ikinci şans, level atlama
- **Banner (opsiyonel):** Level seçim ekranında alt banner — oynanış ekranında **kesinlikle olmamalı** (UX'i bozar)

**Teknik Gereksinimler**
- Test ad unit ID'leri ile geliştirme, production ID'leri store'a göndermeden önce değiştirilmeli
- Ad yükleme başarısız olursa oyun akışını bloklamayan fallback mantığı (reklam gelmezse level otomatik açılmalı)
- Reklam sıklığı sunucu taraflı config (Remote Config) ile kontrol edilebilir olmalı — yayın sonrası ayar değiştirmek için kod güncellemesi gerekmesin

**Çocuk Kullanıcı Riski (Kolay mod)**
Kolay mod çocukları çekebileceğinden, AdMob'da **"child-directed" / family-friendly reklam** ayarları gözden geçirilmeli; yaş beyanına göre reklam kişiselleştirmesi kısıtlanabilir (bkz. Bölüm 5).

## 5. Apple App Store Yönetmeliği — Kontrol Listesi

- [ ] **App Tracking Transparency (ATT)**: Reklam kişiselleştirmesi için IDFA kullanılıyorsa, kullanıcıdan izin isteyen ATT prompt'u eklenmeli
- [ ] **Gizlilik Politikası** linki (App Store Connect + uygulama içi Ayarlar ekranı)
- [ ] **Kullanım Koşulları** (EULA) linki
- [ ] **Privacy Nutrition Label**: App Store Connect'te toplanan veri türleri (analytics, reklam ID) doğru beyan edilmeli
- [ ] **Yaş Derecelendirmesi**: İçerik anketi doğru doldurulmalı (reklam içeriği nedeniyle genelde 4+ değil, reklam SDK'ları yüzünden 9+ veya 12+ çıkabilir)
- [ ] **In-App Purchase (Reklamları Kaldır)**: Apple'ın IAP altyapısı zorunlu (dış ödeme linki yasak), "Restore Purchases" butonu bulunmalı
- [ ] **Reklam içeriği**: Yanıltıcı/agresif reklam SDK'ları kullanılmamalı, reklamlar oyunun kendi arayüzüyle karıştırılmamalı (ör. sahte "kapat" butonu olmamalı)
- [ ] **Kapatma butonu**: Tüm reklamların (özellikle rewarded/interstitial) net görünür bir kapatma (X) butonu olmalı, gecikmeli kapanma Apple'da sorun çıkarabilir
- [ ] **Sign in gerekmiyor** ama eğer ileride hesap sistemi eklenirse "Sign in with Apple" seçeneği sunulmalı (üçüncü parti login varsa zorunlu)
- [ ] **Ekran görüntüleri**: iPhone 6.9" ve iPad (varsa) için güncel screenshot boyutları
- [ ] **Uygulama içi tüm metinler** App Store dil beyanıyla (TR/EN) tutarlı olmalı

## 6. Ekran Tasarımları

1. **Splash Ekranı** — Logo animasyonu (tek çizgi çizilerek belirir), 1-2 sn
2. **Onboarding (3 ekran, kaydırmalı)**
   - Ekran 1: "Parmağını kaldırmadan şekli tamamla" — mekanik gösterimi (kısa animasyon/GIF benzeri illüstrasyon)
   - Ekran 2: "Kolay, Orta, Zor — sana uygun modu seç" — 3 mod görseli
   - Ekran 3: "Yıldız kazan, ipucu topla, rekor kır" — puan/yıldız sistemi tanıtımı
   - Alt kısımda "Geç" (skip) seçeneği + ilerleme noktaları (dot indicator)
3. **Mod Seçim Ekranı** — Kolay/Orta/Zor kartları (renk kodlu), her kartta ilerleme yüzdesi
4. **Level Haritası** — Seçilen moda ait level'lar yol/patika şeklinde dizili, kilitli/açık level ayrımı, yıldız gösterimi
5. **Oynanış Ekranı** — Üstte level no + hamle/süre sayacı, ortada çizim alanı, altta ipucu/undo butonları
6. **Level Tamamlandı Ekranı** — Kazanılan yıldız + puan animasyonu, "Devam Et" butonu, (interstitial burada tetiklenir)
7. **Ayarlar Ekranı** — Tema rengi seçici, koyu/açık mod, dil (TR/EN), ses/haptic aç-kapa, Gizlilik/Koşullar linkleri, Restore Purchases
8. **Mağaza / Reklamları Kaldır Ekranı** — Tek IAP kartı, fiyat, "Satın Al" + "Satın Alımları Geri Yükle"
9. **Profil / Başarımlar Ekranı** — Toplam puan, kazanılan yıldızlar, başarım rozetleri, liderlik tablosu linki

## 7. Onboarding Akışı (Adım Adım)
1. Uygulama açılır → Splash (logo animasyonu)
2. İlk kez açılışta → 3 ekranlık onboarding (yukarıdaki), "Geç" ile atlanabilir
3. Onboarding sonunda otomatik olarak **Kolay mod, Level 1** açılır — interaktif tutorial (gerçek level içinde yönlendirme okları/parmak animasyonu ile mekanik öğretilir)
4. Tutorial level tamamlanınca → Mod Seçim ekranına yönlendirme, kullanıcı burada isterse Orta/Zor'a geçebilir
5. İlk level'larda **reklam gösterilmez** (ilk 2-3 level ad-free — kullanıcıyı erken kaybetmemek için)

## 8. Store Görselleri Gereksinimleri
- **Uygulama ikonu:** 1024×1024 px, PNG, şeffaflık yok
- **App Store screenshot boyutları:** 6.9" (1320×2868) zorunlu, isteğe bağlı diğer boyutlar
- **Google Play:** Feature graphic 1024×500, ikon 512×512
- **Önizleme videosu (opsiyonel ama önerilir):** 15-30 sn, çizim mekaniğini ve 3 modu gösteren kısa video — dönüşüm oranını belirgin şekilde artırır
