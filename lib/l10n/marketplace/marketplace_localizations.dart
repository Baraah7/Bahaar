import 'package:flutter/material.dart';

class MarketplaceLocalizations {
  const MarketplaceLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static MarketplaceLocalizations of(BuildContext context) =>
      MarketplaceLocalizations._(Localizations.localeOf(context));

  String get localeName => _locale.languageCode;

  String get marketplace => _isAr ? 'السوق' : 'Market';
  String get sellFish => _isAr ? 'بيع سمك' : 'Sell Fish';
  String get myOrders => _isAr ? 'الطلبات' : 'Orders';
  String get searchOrders => _isAr ? 'ابحث في الطلبات...' : 'Search orders...';
  String get filterByStatus => _isAr ? 'تصفية حسب الحالة' : 'Filter by Status';
  String get allStatuses => _isAr ? 'جميع الحالات' : 'All Statuses';
  String get searchFishSellerLocation => _isAr ? 'ابحث عن سمك، بائع، موقع...' : 'Search fish, seller, location...';
  String get type => _isAr ? 'النوع' : 'Type';
  String get condition => _isAr ? 'الحالة' : 'Condition';
  String get clearFilters => _isAr ? 'مسح المرشحات' : 'Clear Filters';
  String get filtersActive => _isAr ? 'مرشحات نشطة' : 'filters active';
  String get filterByFishType => _isAr ? 'تصفية حسب نوع السمك' : 'Filter by Fish Type';
  String get allTypes => _isAr ? 'جميع الأنواع' : 'All Types';
  String get filterByCondition => _isAr ? 'تصفية حسب الحالة' : 'Filter by Condition';
  String get allConditions => _isAr ? 'جميع الحالات' : 'All Conditions';
  String get noFishListingsFound => _isAr ? 'لم يتم العثور على قوائم أسماك' : 'No fish listings found';
  String get tryAdjustingFilters => _isAr ? 'حاول تعديل المرشحات' : 'Try adjusting your filters';
  String get orderPlaced => _isAr ? 'تم تقديم الطلب!' : 'Order Placed!';
  String get yourFishListingPosted => _isAr ? 'تم نشر قائمة سمكك!' : 'Your fish listing has been posted!';
  String get orderAccepted => _isAr ? 'تم قبول الطلب!' : 'Order accepted!';
  String get orderRejected => _isAr ? 'تم رفض الطلب' : 'Order rejected';
  String get orderCompleted => _isAr ? 'تم تحديد الطلب كمكتمل!' : 'Order marked as completed!';
  String get rejectOrder => _isAr ? 'رفض الطلب' : 'Reject Order';
  String get areYouSureRejectOrder => _isAr ? 'هل أنت متأكد أنك تريد رفض هذا الطلب؟' : 'Are you sure you want to reject this order?';
  String get reasonOptional => _isAr ? 'السبب (اختياري)' : 'Reason (optional)';
  String get reject => _isAr ? 'رفض' : 'Reject';
  String get accept => _isAr ? 'قبول' : 'Accept';
  String get markAsCompleted => _isAr ? 'تحديد كمكتمل' : 'Mark as Completed';
  String get buyer => _isAr ? 'المشتري' : 'Buyer';
  String get paymentProof => _isAr ? 'إثبات الدفع' : 'Payment Proof';
  String get tapToViewFullImage => _isAr ? 'اضغط لعرض الصورة كاملة' : 'Tap to view full image';
  String get sellerInformation => _isAr ? 'معلومات البائع' : 'Seller Information';
  String get description => _isAr ? 'الوصف' : 'Description';
  String get yourInformation => _isAr ? 'معلوماتك' : 'Your Information';
  String get selectPaymentMethod => _isAr ? 'اختر طريقة الدفع' : 'Select Payment Method';
  String get buyNow => _isAr ? 'اشتري الآن' : 'Buy Now';
  String get contactSeller => _isAr ? 'تواصل مع البائع' : 'Contact Seller';
  String get yourName => _isAr ? 'اسمك' : 'Your Name';
  String get phoneNumber => _isAr ? 'رقم الهاتف' : 'Phone Number';
  String get deliveryLocationOptional => _isAr ? 'موقع التوصيل (اختياري)' : 'Delivery Location (optional)';
  String get pleaseEnterYourName => _isAr ? 'يرجى إدخال اسمك' : 'Please enter your name';
  String get pleaseEnterPhoneNumber => _isAr ? 'يرجى إدخال رقم هاتفك' : 'Please enter your phone number';
  String get uploadPaymentProof => _isAr ? 'رفع إثبات الدفع' : 'Upload Payment Proof';
  String get required => _isAr ? 'مطلوب' : 'Required';
  String get pleaseUploadPaymentScreenshot => _isAr
      ? 'يرجى رفع لقطة شاشة لدفعتك عبر Benefit Pay'
      : 'Please upload a screenshot of your Benefit Pay payment';
  String get tapToUploadScreenshot => _isAr ? 'اضغط لرفع لقطة الشاشة' : 'Tap to upload screenshot';
  String get paymentProofUploaded => _isAr ? 'تم رفع إثبات الدفع' : 'Payment proof uploaded';
  String get pleaseUploadPaymentProofScreenshot => _isAr
      ? 'يرجى رفع لقطة شاشة إثبات الدفع'
      : 'Please upload your payment proof screenshot';
  String get pricePerKg => _isAr ? 'السعر لكل كيلو' : 'Price per kg';
  String get totalPrice => _isAr ? 'السعر الإجمالي' : 'Total Price';
  String get catchLocation => _isAr ? 'موقع الصيد' : 'Catch Location';
  String get catchDate => _isAr ? 'تاريخ الصيد' : 'Catch Date';
  String get cash => _isAr ? 'نقداً' : 'Cash';
  String get benefitPay => _isAr ? 'Benefit Pay' : 'Benefit Pay';
  String get payWithCashOnDelivery => _isAr ? 'الدفع نقداً عند الاستلام' : 'Pay with cash on delivery';
  String get payInstantlyViaBenefitPay => _isAr ? 'الدفع فوراً عبر Benefit Pay' : 'Pay instantly via Benefit Pay';
  String get sales => _isAr ? 'مبيعات' : 'sales';
  String get fishPhotos => _isAr ? 'صور الأسماك' : 'Fish Photos';
  String get addPhotosOfFish => _isAr ? 'أضف صوراً لأسمالك (اختياري)' : 'Add photos of your fish (optional)';
  String get addPhoto => _isAr ? 'إضافة صورة' : 'Add Photo';
  String get fishDetails => _isAr ? 'تفاصيل السمك' : 'Fish Details';
  String get fishType => _isAr ? 'نوع السمك' : 'Fish Type';
  String get customFishName => _isAr ? 'اسم سمك مخصص' : 'Custom Fish Name';
  String get pleaseEnterFishName => _isAr ? 'يرجى إدخال اسم السمك' : 'Please enter the fish name';
  String get weightKg => _isAr ? 'الوزن (كجم)' : 'Weight (kg)';
  String get pricePerKgBD => _isAr ? 'السعر لكل كجم (BD)' : 'Price per kg (BD)';
  String get catchLocationOptional => _isAr ? 'موقع الصيد (اختياري)' : 'Catch Location (optional)';
  String get descriptionOptional => _isAr ? 'الوصف (اختياري)' : 'Description (optional)';
  String get paymentMethods => _isAr ? 'طرق الدفع' : 'Payment Methods';
  String get selectAcceptedPaymentMethods => _isAr ? 'اختر طرق الدفع المقبولة:' : 'Select accepted payment methods:';
  String get acceptCashPayment => _isAr ? 'قبول الدفع نقداً' : 'Accept cash payment';
  String get acceptBenefitPay => _isAr ? 'قبول Benefit Pay' : 'Accept Benefit Pay';
  String get benefitPayQRCode => _isAr ? 'رمز QR للـ Benefit Pay / معلومات الدفع' : 'Benefit Pay QR Code / Payment Info';
  String get uploadBenefitPayQRCode => _isAr ? 'رفع رمز QR للـ Benefit Pay' : 'Upload Benefit Pay QR Code';
  String get buyersWillSeeThis => _isAr ? 'سيرى المشترون هذا عند اختيار Benefit Pay' : 'Buyers will see this when they select Benefit Pay';
  String get postListing => _isAr ? 'نشر القائمة' : 'Post Listing';
  String get yourLocation => _isAr ? 'موقعك (اختياري)' : 'Your Location (optional)';
  String get invalidNumber => _isAr ? 'رقم غير صالح' : 'Invalid number';
  String get loginRequired => _isAr ? 'تسجيل الدخول مطلوب' : 'Login Required';
  String get guestAccountLoginMessage => _isAr
      ? 'تحتاج إلى تسجيل الدخول لإتمام الطلب.\nحسابات الضيف لا يمكنها الشراء أو البيع.'
      : 'You need to sign in to place an order.\nGuest accounts cannot buy or sell fish.';
  String get guestAccountSellMessage => _isAr
      ? 'تحتاج إلى تسجيل الدخول لنشر عرض.\nحسابات الضيف لا يمكنها بيع الأسماك.'
      : 'You need to sign in to post a listing.\nGuest accounts cannot sell fish.';
  String get signInToSell => _isAr ? 'سجّل الدخول لبيع صيدك.' : 'Sign in to sell your catch.';
  String get logIn => _isAr ? 'تسجيل الدخول' : 'Log In';
  String get cancel => _isAr ? 'إلغاء' : 'Cancel';
  String get confirm => _isAr ? 'تأكيد' : 'Confirm';
  String get done => _isAr ? 'تم' : 'Done';
  String get weight => _isAr ? 'الوزن' : 'Weight';
  String get total => _isAr ? 'الإجمالي' : 'Total';
  String get payment => _isAr ? 'الدفع' : 'Payment';
  String get kgUnit => _isAr ? 'كجم' : 'kg';
  String get bdUnit => _isAr ? 'د.ب.' : 'BD';
  String get bdPerKg => _isAr ? 'د.ب./كجم' : 'BD/kg';
  String get sellerLabel => _isAr ? 'البائع' : 'Seller';
  String get rejectionReason => _isAr ? 'السبب' : 'Reason';
  String get waitingForSellerToAccept => _isAr ? 'في انتظار قبول البائع لطلبك' : 'Waiting for seller to accept your order';
  String get orderAcceptedContactSeller => _isAr
      ? 'تم قبول الطلب! تواصل مع البائع لترتيب الاستلام.'
      : 'Order accepted! Contact seller to arrange pickup.';
  String get cancelOrder => _isAr ? 'إلغاء الطلب' : 'Cancel Order';
  String get confirmCancelOrder => _isAr ? 'هل أنت متأكد أنك تريد إلغاء هذا الطلب؟' : 'Are you sure you want to cancel this order?';
  String get orderCancelled => _isAr ? 'تم إلغاء الطلب' : 'Order cancelled';
  String get resellListing => _isAr ? 'إعادة عرض للبيع' : 'Resell';
  String get buyerCancelledOrder => _isAr ? 'قام المشتري بإلغاء هذا الطلب' : 'Buyer cancelled this order';
  String get listingRelistedSuccess => _isAr ? 'تمت إعادة عرض السمك للبيع' : 'Listing is now available again';
  String get benefitPayIban => _isAr ? 'IBAN للـ Benefit Pay' : 'Benefit Pay IBAN';
  String get enterIban => _isAr ? 'أدخل رقم IBAN' : 'Enter IBAN number';
  String get ibanOrQrRequired => _isAr ? 'يرجى رفع رمز QR أو إدخال رقم IBAN' : 'Please upload QR code or enter IBAN number';
  String get deleteListing => _isAr ? 'حذف القائمة' : 'Delete Listing';
  String get confirmDeleteListing => _isAr ? 'إزالة هذه القائمة من السوق؟' : 'Remove this listing from the marketplace?';
  String get listingDeleted => _isAr ? 'تم حذف القائمة' : 'Listing deleted';
  String get or => _isAr ? 'أو' : 'OR';
  String get priceRange => _isAr ? 'السعر' : 'Price';
  String priceRangeFilter(String min, String max) => _isAr
      ? 'السعر: $min–$max BD/كجم'
      : 'Price: $min–$max BD/kg';
  String get allPrices => _isAr ? 'جميع الأسعار' : 'All Prices';
  String get orderPlacedTitle => _isAr ? 'تم تقديم الطلب!' : 'Order Placed!';
  String youHaveOrderedFish(String fish) => _isAr ? 'لقد طلبت $fish' : 'You have ordered $fish';
  String get pleaseLoginToOrder => _isAr ? 'يرجى تسجيل الدخول لتقديم طلب' : 'Please login to place an order';
  String get ibanOptional => _isAr ? 'IBAN (اختياري)' : 'IBAN (optional)';
  String get sellerBenefitNote => _isAr
      ? 'سيرى المشتري تفاصيل Benefit Pay الخاصة بك لإتمام الدفع'
      : 'Buyer will see your Benefit Pay details to complete payment';
  String get phoneEightDigits => _isAr ? 'يجب أن يتكون رقم الهاتف من 8 أرقام' : 'Phone number must be 8 digits';
  String get selectLocationFirst => _isAr ? 'يرجى تحديد موقع أولاً' : 'Please select a location first';
  String get unexpectedError => _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
  String get failedToUploadImage => _isAr ? 'فشل رفع الصورة. يرجى المحاولة مرة أخرى' : 'Failed to upload image. Please try again';
  String get fresh => _isAr ? 'طازج' : 'Fresh';
  String get frozen => _isAr ? 'مجمد' : 'Frozen';
  String get live => _isAr ? 'حي' : 'Live';
  String get cleaned => _isAr ? 'منظف' : 'Cleaned';
  String get filleted => _isAr ? 'مفلل' : 'Filleted';
  String get pending => _isAr ? 'في الانتظار' : 'Pending';
  String get accepted => _isAr ? 'مقبول' : 'Accepted';
  String get rejected => _isAr ? 'مرفوض' : 'Rejected';
  String get completed => _isAr ? 'مكتمل' : 'Completed';
  String get cancelled => _isAr ? 'ملغى' : 'Cancelled';
  String get minAgo => _isAr ? 'دقيقة مضت' : 'min ago';
  String get hoursAgo => _isAr ? 'ساعات مضت' : 'hours ago';
  String get daysAgo => _isAr ? 'أيام مضت' : 'days ago';
  String get fromYourFishingLog => _isAr ? 'من سجل الصيد الخاص بك' : 'From Your Fishing Log';
  String get tapRecentCatchToFill => _isAr ? 'اضغط على مصيد حديث لملء النموذج' : 'Tap a recent catch to pre-fill the form';
  String get today => _isAr ? 'اليوم' : 'Today';
  String get yesterday => _isAr ? 'أمس' : 'Yesterday';
  String sellingTab(int count) => _isAr ? 'البيع ($count)' : 'Selling ($count)';
  String purchasesTab(int count) => _isAr ? 'المشتريات ($count)' : 'Purchases ($count)';
  String get pleaseLoginToViewOrders => _isAr ? 'يرجى تسجيل الدخول لعرض الطلبات' : 'Please login to view orders';
  String get noOrdersForListings => _isAr ? 'لا توجد طلبات لقوائمك بعد' : 'No orders for your listings yet';
  String get noPurchasesYet => _isAr ? 'لا توجد مشتريات بعد' : 'No purchases yet';
  String get whenSomeoneOrdersYourFish => _isAr ? 'عندما يطلب شخص ما سمكك، سيظهر هنا' : 'When someone orders your fish, it will appear here';
  String get yourPurchasesWillAppear => _isAr ? 'ستظهر مشترياتك هنا' : 'Your purchases will appear here';
  String get waitingForSeller => _isAr ? 'في انتظار موافقة البائع على طلبك.' : 'Waiting for seller to accept your order.';
  String get phoneNumberCopied => _isAr ? 'تم نسخ رقم الهاتف' : 'Phone number copied';
  String get pleaseLoginToSell => _isAr ? 'يرجى تسجيل الدخول للبيع' : 'Please login to sell';
  String get signIn   => _isAr ? 'تسجيل الدخول' : 'Sign In';
  String get name     => _isAr ? 'الاسم'         : 'Name';
  String get phone    => _isAr ? 'الهاتف'        : 'Phone';
  String get location => _isAr ? 'الموقع'        : 'Location';
  String get close    => _isAr ? 'إغلاق'         : 'Close';
  String get removePermanently => _isAr ? 'إزالة نهائية' : 'Remove Permanently';
  String get confirmRemovePermanently => _isAr
      ? 'هل أنت متأكد؟ سيتم حذف هذا العرض نهائيًا ولن يكون متاحًا مرة أخرى.'
      : 'Are you sure? This listing will be permanently deleted and cannot be relisted.';
  String get benefitPayRefundReminder => _isAr
      ? 'دفع المشتري عبر Benefit Pay. يرجى إعادة مبلغ الدفع قبل إعادة النشر.'
      : 'The buyer paid via Benefit Pay. Please return their payment before relisting.';
  String get iHaveReturnedPayment => _isAr ? 'أعدتُ الدفع، أكمل' : 'I\'ve Returned It — Resell';
  String get notYet => _isAr ? 'ليس بعد' : 'Not Yet';
  String get removeFromPurchases => _isAr ? 'إزالة من المشتريات' : 'Remove from Purchases';
  String get listed => _isAr ? 'مُدرج' : 'Listed';
  String get edit => _isAr ? 'تعديل' : 'Edit';
  String get editListing => _isAr ? 'تعديل الإدراج' : 'Edit Listing';
  String get delete => _isAr ? 'حذف' : 'Delete';
  String get quantityKg => _isAr ? 'الكمية (كجم)' : 'Quantity (kg)';
  String get quantityHelp => _isAr ? 'الكمية المتاحة' : 'Available';
  String get invalidQuantity => _isAr ? 'الكمية غير صالحة' : 'Invalid quantity';
  String quantityExceeds(String max) => _isAr ? 'الحد الأقصى $max كجم' : 'Max $max kg available';
}
