# Marketplace Feature — Technical Documentation

## Overview

The Marketplace (سوق) lets Bahraini fishermen sell their fresh catch directly to buyers, without middlemen. Sellers post listings from the app; buyers browse, filter, and place orders — all in real time via Firebase Firestore.

---

## Core Concepts

### FishListing
A listing is a single catch offered for sale. It stores:

| Field | Type | Purpose |
|---|---|---|
| `fishType` | enum (8 types) | Hamour, Safi, Kingfish, Shaari, Subaity, Shrimp, Crab, Other |
| `customFishName` | String? | Used only when fishType = Other |
| `weight` | double (kg) | Available quantity |
| `pricePerKg` | double (BD) | Price in Bahraini Dinar |
| `condition` | enum | Fresh / Frozen / Cleaned / Filleted |
| `acceptedPayments` | List | Cash and/or Benefit Pay |
| `imageUrls` | List\<String\> | Firebase Storage URLs |
| `benefitPayImageUrl` | String? | QR code image for Benefit Pay |
| `benefitPayIban` | String? | IBAN alternative for Benefit Pay |
| `fromCatchId` | String? | Links to a fishing log entry |
| `status` | enum | available → reserved → sold |
| `catchLocation` | String? | Where the fish was caught |

### Order
An order is placed by a buyer against a specific listing.

| Field | Type | Purpose |
|---|---|---|
| `listingId` | String | References the listing |
| `sellerId` / `buyerId` | String | Firebase Auth UIDs |
| `paymentMethod` | enum | Cash or Benefit Pay |
| `paymentProofImageUrl` | String? | Screenshot for Benefit Pay orders |
| `requestedKg` | double? | Partial quantity (null = full listing) |
| `status` | enum | pending → accepted / rejected / cancelled / completed |
| `sellerNote` | String? | Message from seller on accept |
| `rejectionReason` | String? | Message from seller on reject |

---

## Firestore Structure

```
/listings/{listingId}          ← all listings, real-time stream
/orders/{orderId}              ← all orders
  .buyerId  = UID              ← queried by buyer
  .sellerId = UID              ← queried by seller
```

Security rules require `buyerId == request.auth.uid` for buyer queries and `sellerId == request.auth.uid` for seller queries, so users can only read their own orders.

---

## Architecture

```
MarinerHarvestPage (ConsumerStatefulWidget)
│
├── FishMarketplaceService (ChangeNotifier)
│   ├── Firestore stream: /listings → _listings
│   ├── Firestore stream: /orders where buyerId == uid → _buyerOrdersList
│   └── Firestore stream: /orders where sellerId == uid → _sellerOrdersList
│       └── _mergeAndNotify() → unified _orders list
│
├── Tab 0 — MarketplaceTab    (browse & buy)
│   └── FishDetailsSheet      (buy form + order placement)
│
├── Tab 1 — SellFishForm      (post a new listing)
│
└── Tab 2 — OrdersTab         (selling history + purchases)
    ├── Selling sub-tab        (listings + incoming orders)
    └── Purchases sub-tab      (buyer's own orders)
```

---

## Feature Flows

### 1. Posting a Listing (Seller)

1. Seller opens **Sell Fish** tab.
2. Fills in: fish type, weight, price/kg, condition, payment methods, optional photos.
3. **Fishing log integration**: if the seller has recent catches, a suggestion row appears. Tapping a catch pre-fills fish type, weight, notes, and catch location automatically — the catch ID is stored as `fromCatchId` so the same catch can't be suggested twice.
4. For Benefit Pay, seller uploads a QR code image and/or enters an IBAN.
5. On submit, images are uploaded to Firebase Storage; the listing document is written to Firestore and immediately appears in the browse tab via the real-time stream.

### 2. Browsing & Buying (Buyer)

1. Buyer opens **Market** tab — listings stream live from Firestore.
2. Buyer can filter by: fish type, condition, price range, payment method, or search by name/seller/location.
3. Tapping a listing opens `FishDetailsSheet` — shows photos, catch location, seller info, and price.
4. Buyer selects payment method, enters their name, phone, and optional delivery location.
5. If Benefit Pay is selected and the seller has a QR code, the buyer sees it to complete payment before submitting.
6. **Partial orders**: the buyer can request a specific quantity (e.g., 3 kg from a 10 kg listing). The remaining weight is subtracted from the listing — it stays available for others.
7. On order placement: a Firestore document is created in `/orders`; the listing status changes to `reserved` (full order) or stays `available` with reduced weight (partial). The order appears immediately in the buyer's Purchases tab via optimistic UI.

### 3. Order Lifecycle (Seller)

The seller sees incoming orders in the **Selling** tab. Each order card expands to show buyer details, payment proof (if Benefit Pay), and action buttons:

```
pending → [Accept / Reject]
accepted → [Mark as Completed]
rejected → listing reverts to available; seller can Resell
completed → listing marked as sold; seller's total_sales incremented
cancelled (by buyer) → seller can remove permanently
```

Push notification is triggered on new pending orders via `NotificationService`.

### 4. Order Lifecycle (Buyer)

```
pending   → waiting for seller; buyer can Cancel
accepted  → seller accepted; buyer contacts seller to arrange pickup
rejected  → seller declined; shown rejection reason
completed → transaction done
cancelled → buyer cancelled
```

### 5. Editing a Listing

Seller taps **Edit** on a listed order card → the full `SellFishForm` opens pre-filled with all existing values (fish type, weight, price, photos, payment info). On submit, the listing document is updated in Firestore. Existing Firebase Storage image URLs are preserved — only new local images are re-uploaded.

### 6. Deleting a Listing

- **Active listing**: seller taps Delete → `removeListing()` deletes the Firestore document.
- **Cancelled order**: seller taps Remove Permanently → both the order document and the listing document are deleted from Firestore. If the buyer paid via Benefit Pay, a reminder to refund the buyer is shown first.

---

## Real-time & Optimistic Updates

`FishMarketplaceService` uses two split Firestore streams (buyer + seller) merged by `_mergeAndNotify()`. When the seller accepts/rejects/completes an order, the status is updated **optimistically** in memory before the Firestore write completes. A `_pendingStatusUpdates` map prevents stale stream snapshots from reverting the optimistic change.

---

## Data Flow Diagram

```
Seller posts listing
        │
        ▼
Firebase Storage ← images uploaded
        │
        ▼
Firestore /listings ←─────────────────────────────────┐
        │                                              │
        ▼ (real-time stream)                           │ status update
MarketplaceTab (all buyers see it)           rejectOrder() / completeOrder()
        │
        ▼
Buyer taps → FishDetailsSheet → createOrder()
        │
        ▼
Firestore /orders
        │
        ├── Seller stream → OrdersTab (Selling)
        └── Buyer stream  → OrdersTab (Purchases)
```

---

## 1-Minute Presentation Script

> "The Marketplace lets fishermen sell their catch directly from the dock — no middlemen.
>
> A seller posts a listing in seconds: they pick the fish type, weight, price per kilo, condition, and photos. If they've already logged the catch in the Fishing Log, the form auto-fills from that entry. They choose which payment methods they accept — cash or Benefit Pay — and post. The listing appears live to all buyers instantly via Firestore real-time streams.
>
> A buyer browses the market, filters by fish type or price, taps a listing, and places an order. They can request a partial quantity — say 3 kg from a 10 kg listing — and the remaining weight stays available for the next buyer.
>
> The seller gets a push notification, sees the order in their Selling tab, and accepts or rejects it. On acceptance, both parties can arrange pickup. When the deal is done, the seller marks it as completed, the listing is marked sold, and their total sales count goes up.
>
> Everything is real time. Status changes appear on both sides within seconds, without any manual refresh."

---

## Examiner Q&A

**Q: Why Firebase Firestore instead of a custom backend?**
> Firestore gives us real-time listeners out of the box — when a seller accepts an order, the buyer's screen updates in seconds without polling. Building that with a custom REST API would require WebSockets or long polling, significantly more infrastructure, and more code to maintain. For a fish market where freshness and immediacy matter, real-time sync is a core requirement, not a nice-to-have.

**Q: How do you prevent a buyer from seeing another buyer's orders?**
> Firestore Security Rules. The buyer's order query filters by `buyerId == request.auth.uid`, and the rule only allows the read if `request.auth.uid == resource.data.buyerId`. Same for the seller. No client-side filtering is involved — unauthorized reads fail at the database level.

**Q: What happens if two buyers order the same listing at the same time?**
> The first order to reach Firestore wins and the listing is marked `reserved`. The second buyer's order will still be created in Firestore, but the seller will see both and can reject the duplicate. A more robust solution would use a Firestore transaction, but given Bahrain's market scale and the speed of resolution, the current approach is practical.

**Q: How does Benefit Pay work in the app — is it integrated with an API?**
> No external payment API. The seller uploads their Benefit Pay QR code or IBAN when creating the listing. When a buyer selects Benefit Pay, they see the seller's QR code in the app, make the transfer in their banking app, then upload a payment screenshot as proof. The seller reviews the screenshot before accepting the order. It's a trust-based flow that matches how Bahraini fishermen actually transact.

**Q: What is the optimistic update pattern you use?**
> When a seller taps Accept/Reject/Complete, we immediately update the order status in memory and call `notifyListeners()` — the UI responds instantly. Then we send the write to Firestore. If the write fails, we revert to the previous state. We also keep a `_pendingStatusUpdates` map so that if a stale Firestore stream snapshot arrives before the write is confirmed, it doesn't undo the local change.

**Q: How does the fishing log integration work?**
> The Sell form shows the seller's 20 most recent fishing log entries. Tapping one pre-fills the fish species, weight, notes, and catch location. The listing stores the catch's ID as `fromCatchId`. The marketplace filters out already-used catch IDs from the suggestion list, so the same catch can't be listed twice accidentally.

**Q: How does partial quantity ordering work?**
> When a buyer requests, say, 3 kg from a 10 kg listing, `createOrder()` subtracts 3 kg from the listing's `weight` field in Firestore and stores `requestedKg: 3` on the order. The listing stays `available` with 7 kg remaining. If the buyer requests the full quantity, the listing changes to `reserved`. On rejection, the weight is restored.

**Q: Can guest users use the marketplace?**
> Guests can browse listings but cannot buy or sell. The Sell tab and the order button are replaced with a locked view that prompts sign-in. This is enforced both in the UI and in Firestore Security Rules, which require `request.auth != null` for all writes.
