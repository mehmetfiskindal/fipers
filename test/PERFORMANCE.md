# Fipers Performance Test Results

Bu dosya Fipers package'inin performans test sonuçlarını içerir.

## Test Senaryoları

### 1. Initialization Performance
- **Açıklama**: Storage'ın initialize edilme süresi
- **Beklenen**: < 5000ms
- **Notlar**: İlk initialization'da salt generation yapılır, bu nedenle biraz daha uzun sürebilir

### 2. Put Operation Performance
- **Küçük Veri (1KB)**: Tek bir küçük veri parçasının şifrelenip saklanması
- **Orta Veri (100KB)**: Orta boyutlu veri için performans
- **Büyük Veri (1MB)**: Büyük veri setleri için performans
- **Beklenen**: 
  - 1KB: < 1000ms
  - 100KB: < 5000ms
  - 1MB: < 10000ms

### 3. Get Operation Performance
- **Küçük Veri (1KB)**: Küçük verinin çözülüp getirilmesi
- **Orta Veri (100KB)**: Orta boyutlu veri için performans
- **Büyük Veri (1MB)**: Büyük veri setleri için performans
- **Beklenen**: 
  - 1KB: < 1000ms
  - 100KB: < 5000ms
  - 1MB: < 10000ms

### 4. Delete Operation Performance
- **Açıklama**: Veri silme işleminin performansı
- **Beklenen**: < 1000ms

### 5. Batch Operations Performance
- **Batch Put (100 items)**: 100 adet 1KB verinin sırayla saklanması
- **Batch Get (100 items)**: 100 adet verinin sırayla getirilmesi
- **Beklenen**: < 30000ms toplam süre

### 6. Mixed Operations Performance
- **Açıklama**: Put/Get/Delete operasyonlarının karışık kullanımı
- **Beklenen**: < 30000ms (50 iterasyon)

### 7. String Data Performance
- **Açıklama**: String verilerin UTF-8 encode/decode ile işlenmesi
- **Beklenen**: < 5000ms

### 8. Concurrent Operations Performance
- **Açıklama**: Paralel operasyonların performansı
- **Beklenen**: < 10000ms (10 paralel operasyon)

### 9. Memory Efficiency - Large Dataset
- **Açıklama**: Büyük veri seti (1000 item, ~1MB) ile bellek verimliliği
- **Beklenen**: < 60000ms

### 10. Re-initialization Performance
- **Açıklama**: Aynı passphrase ile yeniden initialization
- **Beklenen**: < 5000ms (salt zaten mevcut olduğu için daha hızlı olabilir)

## Test Çalıştırma

```bash
# Tüm performans testlerini çalıştır
flutter test test/performance_test.dart

# Belirli bir test çalıştır
flutter test test/performance_test.dart --plain-name "Put Operation Performance - Small Data"

# Detaylı output ile
flutter test test/performance_test.dart --reporter expanded
```

## Benchmark Sonuçları

Test sonuçları terminalde görüntülenir. Her test için şu bilgiler gösterilir:
- **Zaman**: İşlemin tamamlanma süresi (ms)
- **Throughput**: Veri aktarım hızı (KB/s veya MB/s)
- **Ortalama Zaman**: Batch operasyonlarda item başına ortalama süre

## Performans Metrikleri

### Beklenen Performans Değerleri

| Operasyon | Veri Boyutu | Beklenen Süre | Beklenen Throughput |
|-----------|-------------|---------------|---------------------|
| Init | - | < 5000ms | - |
| Put | 1KB | < 1000ms | > 1 KB/s |
| Put | 100KB | < 5000ms | > 20 KB/s |
| Put | 1MB | < 10000ms | > 0.1 MB/s |
| Get | 1KB | < 1000ms | > 1 KB/s |
| Get | 100KB | < 5000ms | > 20 KB/s |
| Get | 1MB | < 10000ms | > 0.1 MB/s |
| Delete | - | < 1000ms | - |
| Batch Put | 100x1KB | < 30000ms | > 3.3 KB/s |
| Batch Get | 100x1KB | < 30000ms | > 3.3 KB/s |

## Notlar

- Performans değerleri platform, donanım ve sistem yüküne göre değişebilir
- İlk initialization daha uzun sürebilir (salt generation)
- Büyük veri setleri için throughput daha önemlidir
- Concurrent operations thread-safe olmalıdır

