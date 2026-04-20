## TradeHub (Next.js + TypeScript + MSSQL)

Bu proje, MSSQL’deki `ETRADE` veritabanını kullanarak basit bir e-ticaret MVP web sitesi sağlar:

- Ürün listeleme + arama (`ITEMS`)
- Ürün detay + sepete ekleme (sayfada kalır, toast gösterir)
- Sepet (cookie tabanlı)
- Giriş / kayıt (`USERS`)
- Adres seçerek sipariş oluşturma (`ORDERS`, `ORDERDETAILS`, `ADDRESS`)

Teknoloji:

- Next.js (App Router) + TypeScript (TSX)
- Tailwind CSS
- MSSQL bağlantısı: `mssql/msnodesqlv8` (ODBC Driver)

## Getting Started

1) Ortam değişkenleri:

- `.env.local.example` → `.env.local`
- `MSSQL_CONNECTION_STRING` ayarla

Örnek (Integrated / yerel):

`MSSQL_CONNECTION_STRING=Driver={ODBC Driver 18 for SQL Server};Server=.;Database=ETRADE;Trusted_Connection=yes;Encrypt=yes;TrustServerCertificate=yes;`

2) Dev server:

```bash
npm run dev
```

Tarayıcı: `http://localhost:3000/items`

## Notlar

- Auth düz şifre ile çalışır (`AUTH_PLAIN_OK=true`).
- Checkout için ilgili kullanıcıda `ADDRESS` kaydı olmalı.

